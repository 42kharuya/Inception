#!/bin/bash
# Bashスクリプトを失敗に厳しくして不具合を早期に検出するための設定
# -e（errexit）：どこかのコマンドが非0で失敗したらスクリプトを即終了
# -u（nounset）：未定義の変数参照をエラー扱い
# -o pipefail：パイプラインの途中で失敗したコマンドも失敗として検出
set -euo pipefail

SOCKET_PATH="/run/mysqld/mysqld.sock"
BOOTSTRAP_RETRIES=60
BOOTSTRAP_SLEEP_SEC=0.5

die() {
	echo "ERROR: $*" >&2
	exit 1
}

require_env() {
	# ローカル変数nameを宣言し、関数に渡された 第1引数（$1）を代入
	local name="$1"

	# nameの中身が空だった場合はエラー処理
	if [[ -z "${!name:-}" ]]; then
		die "environment variable '$name' is not set"
	fi
}

# Docker Secretsから機密情報を読み取る
load_secrets() {
	if [[ -f "/run/secrets/db_root_password" ]]; then
		MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
		export MYSQL_ROOT_PASSWORD
	fi

	if [[ -f "/run/secrets/db_password" ]]; then
		MYSQL_PASSWORD=$(cat /run/secrets/db_password)
		export MYSQL_PASSWORD
	fi
}

# 初期化に必要な環境変数がすべて揃っているかを確認
# もし環境変数の中身が空だったらエラー出力をしてexitしてくれる
load_secrets
require_env MYSQL_DATABASE
require_env MYSQL_USER
require_env MYSQL_PASSWORD
require_env MYSQL_ROOT_PASSWORD

ensure_runtime_dirs() {
	# プロセスIDファイル（PID ファイル）やソケットファイルが保存される場所
	mkdir -p /run/mysqld
	# /run/mysqldの所有者（user）と所有グループ（group）をmysqlに変更
	# MariaDB/MySQL デーモンプロセスを実行するための専用ユーザー
	chown -R mysql:mysql /run/mysqld
}

start_bootstrap_server() {
	# MariaDBを一時起動（初期設定を流し込むため）
	# Debianのinitスクリプト(service mariadb start)は環境によってroot接続の試行ログを出すことがあるため、
	# ここではサーバを直接起動して初期化します。
	# mysqld_safeはmysqldのラッパーコマンド
	mysqld_safe --skip-networking --socket="${SOCKET_PATH}" &
	BOOTSTRAP_PID=$!
}

# 実行コマンド（配列）
MYSQL_CLI=()
BOOTSTRAP_PID=""

# パスワードなしの起動コマンド
can_connect_root_no_password() {
	mariadb --protocol=socket -uroot -e "SELECT 1" >/dev/null 2>&1
}

# パスワードありの起動コマンド
can_connect_root_with_password() {
	mariadb --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1
}

detect_root_mysql_cli() {
	local _
	for _ in $(seq 1 "${BOOTSTRAP_RETRIES}"); do
		if can_connect_root_no_password; then
			MYSQL_CLI=(mariadb --protocol=socket -uroot)
			return 0
		fi
		if can_connect_root_with_password; then
			MYSQL_CLI=(mariadb --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}")
			return 0
		fi
		sleep "${BOOTSTRAP_SLEEP_SEC}"
	done

	return 1
}

assert_root_connection_detected() {
	if [[ ${#MYSQL_CLI[@]} -eq 0 ]]; then
		echo "ERROR: cannot connect to MariaDB as root (password may not match or server not ready)" >&2
		echo "Hint: if you previously ran the container, try: docker compose down -v && docker compose up --build" >&2
		exit 1
	fi
}

run_init_sql() {
	# やっていること
	# ・データベース新規作成（存在しない場合）
	# ・ユーザーを新規作成（存在しない場合）
	# ・データベースの権限をユーザーに付与
	# ・ルートに認証用パスワードを設定
	"${MYSQL_CLI[@]}" <<-EOSQL
		CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

		-- ローカルでの動作確認用（任意）
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';

		ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
		FLUSH PRIVILEGES;
	EOSQL
}

shutdown_bootstrap_server() {
	# パスワードありルートとパスワードなしルートで停止コマンドを分岐
	if can_connect_root_with_password; then
		mariadb-admin --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
	else
		mariadb-admin --protocol=socket -uroot shutdown
	fi

	ブートストラッププロセス（一時起動したサーバ）のクリーンアップ
	wait "${BOOTSTRAP_PID}" 2>/dev/null || true
}

main() {
	# 1. MariaDBを一時起動（初期設定を流し込むため）
	# ソケット生成後、mysqlがアクセスできるように権限変更
	ensure_runtime_dirs
	# mysqld_safe起動
	start_bootstrap_server

	# 2. mysqld_safe起動待ち + root接続方法の自動判別
	if detect_root_mysql_cli; then
		:
	fi
	# 起動コマンドのエラー処理
	assert_root_connection_detected

	# 3. SQLコマンドを順番に実行
	run_init_sql

	# 4. 一時起動したサーバを停止して、本番プロセスとして再起動
	shutdown_bootstrap_server

	# 本番起動（mysqld_safe は MariaDB の標準的な起動コマンドです）
	exec mysqld_safe
}

main "$@"
