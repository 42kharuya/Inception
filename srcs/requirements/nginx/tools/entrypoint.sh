#!/bin/sh

set -eu

# ==============================================
# NGINX Entrypoint
#
# 目的:
# - `.env` から渡される `DOMAIN_NAME` を使って
#   1) NGINX設定ファイルをテンプレートから生成
#   2) 自己署名証明書を生成（CN/SAN を DOMAIN_NAME に一致させる）
#
# このスクリプトはコンテナ起動時に毎回実行されます。
# 証明書はすでに存在する場合は基本的に再生成しませんが、
# DOMAIN_NAME が変わった場合は自動で再生成します。
# ==============================================

# DOMAIN_NAME は必須（未設定ならここで終了）
: "${DOMAIN_NAME:?environment variable DOMAIN_NAME is not set}"

# 証明書と鍵の配置先
SSL_DIR="/etc/nginx/ssl"
CERT_PATH="${SSL_DIR}/inception.crt"
KEY_PATH="${SSL_DIR}/inception.key"
# 前回どのドメイン名で証明書を作ったかを記録するファイル
DOMAIN_MARKER_PATH="${SSL_DIR}/.domain_name"

# ディレクトリが無ければ作成
mkdir -p "${SSL_DIR}"

# 証明書が必要かどうかを判定する:
# - 初回起動（証明書/鍵が無い） → 生成
# - DOMAIN_NAME が変更された（マーカー不一致） → 再生成
NEED_CERT_REGEN=0
if [ ! -f "${CERT_PATH}" ] || [ ! -f "${KEY_PATH}" ]; then
	NEED_CERT_REGEN=1
elif [ ! -f "${DOMAIN_MARKER_PATH}" ] || [ "$(cat "${DOMAIN_MARKER_PATH}" 2>/dev/null || true)" != "${DOMAIN_NAME}" ]; then
	NEED_CERT_REGEN=1
fi

if [ "${NEED_CERT_REGEN}" -eq 1 ]; then
	# -nodes: 秘密鍵を暗号化しない（コンテナ起動時に対話ができないため）
	# -subj: 証明書の識別情報（CNにDOMAIN_NAMEを使う）
	# -addext subjectAltName: ブラウザ等はSANを見るため、DNS:DOMAIN_NAMEを付与
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout "${KEY_PATH}" \
		-out "${CERT_PATH}" \
		-subj "/C=JP/ST=Tokyo/L=Shinjuku/O=42Tokyo/OU=Student/CN=${DOMAIN_NAME}" \
		-addext "subjectAltName=DNS:${DOMAIN_NAME}" \
		>/dev/null 2>&1
	# 次回以降、DOMAIN_NAME が変わったか判定できるよう記録
	printf '%s' "${DOMAIN_NAME}" >"${DOMAIN_MARKER_PATH}"
fi

# NGINX は設定ファイル内で環境変数を展開しないため、
# テンプレート（.template）を envsubst で描画して実ファイル（.conf）にします。
envsubst '$DOMAIN_NAME' </etc/nginx/conf.d/default.conf.template >/etc/nginx/conf.d/default.conf

# CMD で渡されたプロセス（nginx -g 'daemon off;'）を PID 1 として起動
exec "$@"
