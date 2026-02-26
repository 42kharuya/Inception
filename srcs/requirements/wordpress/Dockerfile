FROM debian:bookworm

# MariaDB（クライアント）をインストール (vimは動作確認のためインストール)
# php-fpm: PHPを実行する本体。
# php-mysql: PHPがMariaDBと会話するために必須のプラグイン。
# mariadb-client: コンテナ内からMariaDBに接続確認したり、WP-CLIを動かすために必要。
# curl: WordPress本体やWP-CLIをダウンロードするために使う。
RUN apt-get update && apt-get install -y mariadb-client php-fpm php-mysql curl vim

# WP-CLIの導入(ダウンロード、実行権限付与、パスを通す)
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	chmod +x wp-cli.phar && \
	mv wp-cli.phar /usr/local/bin/wp