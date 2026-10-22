FROM ghcr.io/mhsanaei/3x-ui:latest

# 安装 supervisord 和必要工具
USER root
RUN apk add --no-cache supervisor curl tzdata \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 下载 cloudflared (根据 CPU 架构自动选择，Suga 常见为 amd64)
ARG TARGETARCH
RUN case "${TARGETARCH}" in \
      amd64) CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" ;; \
      arm64) CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64" ;; \
      *) echo "Unsupported arch: ${TARGETARCH}" && exit 1 ;; \
    esac \
    && curl -L -o /usr/local/bin/cloudflared "${CLOUDFLARED_URL}" \
    && chmod +x /usr/local/bin/cloudflared

# supervisord 配置
RUN mkdir -p /var/log/supervisor /etc/supervisor/conf.d
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 保持 3x-ui 原有 ENTRYPOINT 所需的环境变量 (可选，镜像已有默认值)
ENV XUI_DB_FOLDER=/etc/x-ui \
    XUI_LOG_FOLDER=/dev/null

# 用 supervisord 作为 PID 1，替代原镜像的 entrypoint
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
