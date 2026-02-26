FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx openssl

# SSL証明書を保存するフォルダを作成
RUN mkdir -p /etc/nginx/ssl

# 自己署名証明書の発行（対話形式を避けるためにオプションを指定）
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=JP/ST=Tokyo/L=Shinjuku/O=42Tokyo/OU=Student/CN=kharuya.42.fr"

# 設定ファイルをコピー
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

# NGINXをフォアグラウンドで起動
CMD ["nginx", "-g", "daemon off;"]
