FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx openssl

# SSL証明書を保存するフォルダを作成
RUN mkdir -p /etc/nginx/ssl

# 自己署名証明書の発行（対話形式を避けるためにオプションを指定）
# req: 証明書署名要求（Certificate Signing Request）を生成
# -x509: 自己署名証明書を生成
# -nodes: 秘密鍵（private key）を暗号化しない
# -days 365: 証明書の有効期限を365 日間（1 年間）に設定
# -newkey rsa:2048: 2048 ビットのRSA鍵を新規生成
# -keyout: 生成された秘密鍵を /etc/nginx/ssl/inception.key に保存
# -out: 生成された公開鍵と証明書情報を /etc/nginx/ssl/inception.crt に保存
# -subj: 対話形式の入力をスキップするため、証明書の識別情報を直接指定
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=JP/ST=Tokyo/L=Shinjuku/O=42Tokyo/OU=Student/CN=kharuya.42.fr"

# 設定ファイルをコピー
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

# NGINXをフォアグラウンドで起動
CMD ["nginx", "-g", "daemon off;"]
