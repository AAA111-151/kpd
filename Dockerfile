FROM ghcr.io/mhsanaei/3x-ui:latest

USER root
RUN apk add --no-cache supervisor curl tzdata \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ARG TARGETARCH
RUN case "${TARGETARCH}" in \
      amd64) CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" ;; \
      arm64) CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64" ;; \
      *) echo "Unsupported arch: ${TARGETARCH}" && exit 1 ;; \
    esac \
    && curl -L -o /usr/local/bin/cloudflared "${CLOUDFLARED_URL}" \
    && chmod +x /usr/local/bin/cloudflared

RUN mkdir -p /var/log/supervisor /etc/supervisor/conf.d
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENV XUI_DB_FOLDER=/etc/x-ui \
    XUI_LOG_FOLDER=/dev/null

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
