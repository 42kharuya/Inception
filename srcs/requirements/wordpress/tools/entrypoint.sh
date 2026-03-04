#!/bin/bash
# ========================================
# WordPress + PHP-FPMコンテナの初期化スクリプト
# ========================================
# 機能：
#   1. Docker Secretsから機密情報（パスワード）を読み込む
#   2. 必須の環境変数をすべて確認する
#   3. MariaDBが起動するまで待機する
#   4. WordPressがまだインストールされていない場合、WP-CLIで初期化する
#   5. PHP-FPMをフォアグラウンドで起動する（PID 1として）

set -euo pipefail

# ========================================
# 定数定義
# ========================================
DB_HOST="mariadb"      # MariaDBサービス名（docker-compose.ymlのservice名）
DB_PORT="3306"         # MariaDBのポート番号
WP_DIR="/var/www/html" # WordPressがインストールされるディレクトリ
MAX_DB_WAIT=60         # DB起動確認の最大試行回数（秒）
SLEEP_SEC=2            # DB確認の間隔（秒）

# ========================================
# エラーハンドリング関数
# ========================================
# エラーメッセージを stderr に出力して即座に終了する
error() {
	echo "ERROR: $*" >&2
	exit 1
}

# ========================================
# 環境変数検証関数
# ========================================
# 指定された環境変数が空でないことを確認する
# 空だった場合、エラーメッセージを出力して終了
require_env() {
	local name="$1"
	if [[ -z "${!name:-}" ]]; then
		error "environment variable '$name' is not set"
	fi
}

# ========================================
# Docker Secretsをロードする関数
# ========================================
# Docker Composefile で secrets セクションに定義されたファイルから
# 機密値（パスワード）を読み込み、環境変数として export する
load_secrets() {
	# MariaDBアプリケーションユーザーのパスワード
	# docker-compose.yml の secret.db_password で定義
	if [[ -f "/run/secrets/db_password" ]]; then
		MYSQL_PASSWORD="$(cat /run/secrets/db_password)"
		export MYSQL_PASSWORD
	fi

	# WordPressの管理者パスワードと一般ユーザーパスワード
	# credentials.txt から以下を export:
	#   - WP_ADMIN_PASSWORD: WordPress 管理者ユーザーのパスワード
	#   - WP_USER_PASSWORD: WordPress 一般ユーザーのパスワード
	if [[ -f "/run/secrets/credentials" ]]; then
		# shellcheck disable=SC1091
		source /run/secrets/credentials
		export WP_ADMIN_PASSWORD
		export WP_USER_PASSWORD
	fi
}

# ========================================
# MariaDB起動待機関数
# ========================================
# MariaDBコンテナが起動して TCP ポート 3306 で接続可能になるまで待つ
# 無限待機を防ぐため、MAX_DB_WAIT 回まで再試行し、その後エラー終了
wait_for_mariadb() {
	local i
	# ループ回数をカウント（1 から MAX_DB_WAIT まで）
	for i in $(seq 1 "${MAX_DB_WAIT}"); do
		# nc (netcat): TCP接続テスト
		# -z: 接続してすぐに切断（ポートが開いているか確認）
		# ${DB_HOST} ${DB_PORT}: 接続先と口
		if nc -z "${DB_HOST}" "${DB_PORT}"; then
			echo "MariaDB is ready."
			return 0
		fi
		# まだ接続できない場合、進捗を出力して待機
		echo "Waiting for MariaDB (${i}/${MAX_DB_WAIT})..."
		sleep "${SLEEP_SEC}"
	done
	# MAX_DB_WAIT 回の試行後も接続できない場合、エラー終了
	error "MariaDB is not reachable at ${DB_HOST}:${DB_PORT}"
}

# ========================================
# WordPress一般ユーザーの冪等作成関数
# ========================================
# 一般ユーザーが既に存在すれば作成しない（べき等性）
# 存在しなければ新規作成する
create_wp_user_if_missing() {
	# wp user get: WordPress CLIで指定ユーザーが存在するかチェック
	# --allow-root: root で実行を許可（コンテナ内なので必要）
	# /dev/null: 標準出力と標準エラー出力を捨てる
	if ! wp user get "${WP_USER}" --allow-root >/dev/null 2>&1; then
		# ユーザーが存在しない → 新規作成
		wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
			--user_pass="${WP_USER_PASSWORD}" \
			--role=author \
			--allow-root
	fi
}

# ========================================
# メイン処理
# ========================================
main() {
	# 1. 機密値（パスワード）をロード
	load_secrets

	# 2. 必須環境変数をすべてチェック
	# データベース設定
	require_env MYSQL_DATABASE
	require_env MYSQL_USER
	require_env MYSQL_PASSWORD
	# WordPress 設定（ドメイン、サイト情報）
	require_env DOMAIN_NAME
	require_env SITE_TITLE
	# WordPress 管理者アカウント
	require_env WP_ADMIN_USER
	require_env WP_ADMIN_EMAIL
	require_env WP_ADMIN_PASSWORD
	# WordPress 一般ユーザーアカウント
	require_env WP_USER
	require_env WP_USER_EMAIL
	require_env WP_USER_PASSWORD

	# 3. MariaDBが起動するまで待機
	wait_for_mariadb

	# 4. WordPressがまだインストールされていない場合のみ初期化
	# wp-config.php がなければ、インストールが未実施と判定
	if [[ ! -f "${WP_DIR}/wp-config.php" ]]; then
		echo "WordPress is not installed. Starting setup..."
		cd "${WP_DIR}"

		# 4a. WordPress本体をダウンロード
		# wp core download: 最新のWordPress本体をカレントディレクトリに展開
		wp core download --allow-root

		# 4b. wp-config.php を生成
		# 環境変数（MYSQL_DATABASE, MYSQL_USER など）をもとに
		# WordPressの設定ファイルを自動生成
		wp config create --allow-root \
			--dbname="${MYSQL_DATABASE}" \
			--dbuser="${MYSQL_USER}" \
			--dbpass="${MYSQL_PASSWORD}" \
			--dbhost="${DB_HOST}:${DB_PORT}"

		# 4c. WordPressをインストール（DB初期化、管理者ユーザー作成）
		# wp core install: サイトURL、タイトル、管理者アカウント設定
		wp core install --allow-root \
			--url="${DOMAIN_NAME}" \
			--title="${SITE_TITLE}" \
			--admin_user="${WP_ADMIN_USER}" \
			--admin_password="${WP_ADMIN_PASSWORD}" \
			--admin_email="${WP_ADMIN_EMAIL}"

		# 4d. 一般ユーザーも作成
		create_wp_user_if_missing
		echo "WordPress setup completed."
	fi

	# 5. PHP-FMをフォアグラウンドで起動（PID 1として）
	# コンテナの主プロセスとして動作し、終了時にコンテナ全体が停止する
	echo "Starting PHP-FPM..."
	exec "$@"
}

# メイン関数を実行
# $@: Dockerfile の CMD で渡された引数（通常は ["php-fpm8.2", "-F"]）
main "$@"
