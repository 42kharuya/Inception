FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends nginx openssl gettext-base \
    && rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf.template /etc/nginx/conf.d/default.conf.template
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# NGINXをフォアグラウンドで起動
CMD ["nginx", "-g", "daemon off;"]
