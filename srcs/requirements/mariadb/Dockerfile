FROM debian:bookworm

# MariaDB（サーバー）をインストール (vimは動作確認のためインストール)
RUN apt-get update && apt-get install -y mariadb-server vim

# Maria DBのデフォルト設定では、bind-address = 127.0.0.1で自分しかアクセスできない。
# bind-address = 0.0.0.0ですべてのネットワークインターフェースを待ち受けるようにする。
RUN sed -i 's/bind-address = 127.0.0.1/bind-address = 0.0.0.0/g' /etc/mysql/mariadb.conf.d/50-server.cnf

# Maria DBの初期化設定とWordPress用テーブル作成のスクリプトをコンテナにコピー
COPY ./tools/entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/entrypoint.sh

# entrypoint.shをデフォルトの起動コマンドに設定
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# ENTRYPOINT の後に続くデフォルト引数として指定
# コンテナは、デフォルトではrootユーザーで動くので、
# セキュリティの観点からユーザーをmysqlに変更
CMD ["mysqld_safe", "--user=mysql"]
