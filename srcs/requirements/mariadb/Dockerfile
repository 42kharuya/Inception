FROM debian:bookworm

# MariaDB（サーバー）をインストール
# --no-install-recommends: 「推奨」パッケージをスキップ。「必須」パッケージのみインストール
# rm -rf /var/lib/apt/lists/*: ビルド時にダウンロードされたパッケージリストキャッシュを削除。実行時は不要なため、イメージ容量を大幅削減
RUN apt-get update && apt-get install -y --no-install-recommends mariadb-server \
	&& rm -rf /var/lib/apt/lists/*

# MariaDBのデフォルト設定では bind-address = 127.0.0.1 で自コンテナのみ待受になるため、
# 0.0.0.0 に変更して同一Dockerネットワークから接続可能にする。
RUN sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
# Maria DBの初期化設定とWordPress用テーブル作成のスクリプトをコンテナにコピー
COPY ./tools/entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/entrypoint.sh

# entrypoint.shをデフォルトの起動コマンドに設定
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# ENTRYPOINT の後に続くデフォルト引数として指定
# コンテナは、デフォルトではrootユーザーで動くので、
# セキュリティの観点からユーザーをmysqlに変更
CMD ["mysqld_safe", "--user=mysql"]
