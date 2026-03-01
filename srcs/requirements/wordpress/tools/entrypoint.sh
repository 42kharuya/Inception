#!/bin/bash
set -e

# Docker Secretsから機密情報を読み取る
load_secrets() {
	if [[ -f "/run/secrets/db_password" ]]; then
		MYSQL_PASSWORD=$(cat /run/secrets/db_password)
		export MYSQL_PASSWORD
	fi
	
	if [[ -f "/run/secrets/credentials" ]]; then
		# credentialsファイルから読み取り
		source /run/secrets/credentials
		export WP_ADMIN_PASSWORD
		export WP_USER_PASSWORD
	fi
}

# Secretsをロード
load_secrets

# 1. MariaDBが起動するまで待機（これがないと接続エラーになる）
# mariadb-clientを入れているので、mariadb-admin ping で生存確認ができる
until mariadb-admin ping -h"mariadb" --silent; do
    echo "Waiting for MariaDB..."
    sleep 2
done

# 2. WordPressが未インストールの場合のみセットアップを実行
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "WordPress is not installed. Starting setup..."

    # ディレクトリへ移動
    cd /var/www/html

    # 本体のダウンロード
    wp core download --allow-root

    # wp-config.php の作成（環境変数を使用）
    wp config create --allow-root \
        --dbname=$MYSQL_DATABASE \
        --dbuser=$MYSQL_USER \
        --dbpass=$MYSQL_PASSWORD \
        --dbhost=mariadb:3306

    # インストール（サイト名、管理者ユーザーの作成）
    wp core install --allow-root \
        --url=$DOMAIN_NAME \
        --title=$SITE_TITLE \
        --admin_user=$WP_ADMIN_USER \
        --admin_password=$WP_ADMIN_PASSWORD \
        --admin_email=$WP_ADMIN_EMAIL

    # 一般ユーザーも作成
	wp user create $WP_USER $WP_USER_EMAIL \
    	--user_pass=$WP_USER_PASSWORD \
		--role=author \
    	--allow-root

    echo "WordPress setup completed!"
fi

# 3. 本番プロセス（PHP-FPM）をフォアグラウンドで起動
# DockerfileのCMDで "php-fpm7.4 -F" などを渡す場合は exec "$@" を使う
echo "Starting PHP-FPM..."
exec "$@"