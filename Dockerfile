FROM ghcr.io/mhsanaei/3x-ui:latest

# 3x-ui 官方镜像基于 Alpine，补装 supervisor、curl、bash
RUN apk add --no-cache supervisor curl bash tzdata \
    && rm -rf /var/cache/apk/*

# 安装 Komari Agent（构建时安装，启动时不再下载）
RUN curl -sL https://raw.githubusercontent.com/komari-monitor/komari-agent/refs/heads/main/install.sh \
    | bash -s -- --install-only 2>/dev/null || \
    curl -sL -o /usr/local/bin/komari-agent \
    https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent-linux-amd64 \
    && chmod +x /usr/local/bin/komari-agent

# 把 cloudflared 也放进镜像，避免运行时下载
RUN curl -sL -o /usr/local/bin/cloudflared \
    https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    && chmod +x /usr/local/bin/cloudflared

COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV XUI_DB_FOLDER=/data \
    XUI_LOG_FOLDER=/dev/null

VOLUME /data

ENTRYPOINT ["/entrypoint.sh"]
