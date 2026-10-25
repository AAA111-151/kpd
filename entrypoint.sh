#!/bin/sh
set -e

# ===== 必填变量检查 =====
: "${TUNNEL_TOKEN:?TUNNEL_TOKEN is required}"
: "${KOMARI_ENDPOINT:?KOMARI_ENDPOINT is required}"
: "${KOMARI_TOKEN:?KOMARI_TOKEN is required}"

# XUI_PORT 不强制，默认 2053；不硬编码在文件里，由 compose 或 InstaCloud 控制台注入
XUI_PORT="${XUI_PORT:-2053}"

# ===== 写入 /data 卷的持久化目录 =====
mkdir -p /data
chown -R root:root /data 2>/dev/null || true

# ===== 生成 cloudflared 的 supervisord 配置 =====
cat > /etc/supervisor/conf.d/cloudflared.conf <<EOF
[program:cloudflared]
command=/usr/local/bin/cloudflared tunnel --no-autoupdate run
environment=TUNNEL_TOKEN="${TUNNEL_TOKEN}"
autostart=true
autorestart=true
stderr_logfile=/dev/stderr
stdout_logfile=/dev/stdout
stderr_logfile_maxbytes=0
stdout_logfile_maxbytes=0
EOF
# cloudflared 会自动从环境变量 TUNNEL_TOKEN 读取 token，不需要把 token 写进命令行

# ===== 生成 komari-agent 的 supervisord 配置 =====
# 用 command 方式传参，避免纯 env 方式在 Docker 中报“缺少命令”的问题
cat > /etc/supervisor/conf.d/komari.conf <<EOF
[program:komari-agent]
command=/usr/local/bin/komari-agent
    -e "${KOMARI_ENDPOINT}"
    --auto-discovery "${KOMARI_TOKEN}"
    --disable-web-ssh
    --interval 5.0
    --max-retries 5
    --reconnect-interval 10
    --info-report-interval 15
autostart=true
autorestart=true
stderr_logfile=/dev/stderr
stdout_logfile=/dev/stdout
stderr_logfile_maxbytes=0
stdout_logfile_maxbytes=0
EOF

# ===== 生成 x-ui 的 supervisord 配置 =====
# XUI_PORT 通过环境变量传给 x-ui 进程；3x-ui 支持 XUI_PORT 覆盖面板端口
cat > /etc/supervisor/conf.d/xui.conf <<EOF
[program:x-ui]
command=/app/x-ui
environment=XUI_DB_FOLDER="/data",XUI_LOG_FOLDER="/dev/null",XUI_PORT="${XUI_PORT}"
autostart=true
autorestart=true
stderr_logfile=/dev/stderr
stdout_logfile=/dev/stdout
stderr_logfile_maxbytes=0
stdout_logfile_maxbytes=0
EOF

# ===== 启动 supervisord =====
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
