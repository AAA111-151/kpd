FROM ghcr.io/mhsanaei/3x-ui:latest

# 3x-ui 官方镜像基于 Alpine，补装 supervisor、curl、bash
RUN apk add --no-cache supervisor curl bash tzdata \
    && rm -rf /var/cache/apk/*

# 安装 cloudflared（构建时下载，避免运行时依赖网络）
RUN curl -fsSL -o /usr/local/bin/cloudflared \
    https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    && chmod +x /usr/local/bin/cloudflared

# 安装 Komari Agent（直接下载二进制，避免 install.sh 的交互式行为）
RUN curl -fsSL -o /usr/local/bin/komari-agent \
    https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent-linux-amd64 \
    && chmod +x /usr/local/bin/komari-agent

COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && mkdir -p /etc/supervisor/conf.d

ENV XUI_DB_FOLDER=/data \
    XUI_LOG_FOLDER=/dev/null

VOLUME /data

ENTRYPOINT ["/entrypoint.sh"]
