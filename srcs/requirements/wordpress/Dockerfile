FROM debian:bookworm

# php-fpm: PHP実行本体
# php-mysql: PHPからMariaDB接続
# php-cli: WP-CLI実行
# mariadb-client: DB接続確認
# curl: WordPress本体とWP-CLI取得
# netcat-openbsd: TCP接続確認
RUN apt-get update && apt-get install -y --no-install-recommends \
	mariadb-client php-fpm php-mysql curl php-cli netcat-openbsd ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

# PIDディレクトリ作成
RUN mkdir -p /run/php

# WordPress用ディレクトリ作成と権限変更
# www-dataはPHP-FPM がプロセスを実行する際に使用する専用ユーザー
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# WordPressを動かすために、php-fpmの設定ファイルで変更。
# デフォルトの .sock（Unixソケット）は、同じコンピュータ内のプロセス間でしか通信できないので、
# TCPネットワークポート（9000番）で待ち受けるように変更
RUN sed -i 's/listen = \/run\/php\/php8.2-fpm.sock/listen = 0.0.0.0:9000/g' /etc/php/8.2/fpm/pool.d/www.conf
# Docker Composeで設定した環境変数（MYSQL_USERやMYSQL_PASSWORDなど）を保持
RUN sed -i 's/;clear_env = no/clear_env = no/g' /etc/php/8.2/fpm/pool.d/www.conf

# WP-CLIの導入(ダウンロード、実行権限付与、パスを通す)
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	chmod +x wp-cli.phar && \
	mv wp-cli.phar /usr/local/bin/wp

# WordPressがなければインストールし、あればPHP-FPMを起動するスクリプトを設定
COPY ./tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# スクリプトをENTRYPOINTに指定
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# 最後に起動したいコマンドをCMDに指定
CMD ["php-fpm8.2", "-F"]