#!/bin/sh
set -e

# ===== 必填变量检查（使用 Komari Agent 官方变量名）=====
: "${TUNNEL_TOKEN:?TUNNEL_TOKEN is required}"
: "${AGENT_ENDPOINT:?AGENT_ENDPOINT is required}"
: "${AGENT_AUTO_DISCOVERY_KEY:?AGENT_AUTO_DISCOVERY_KEY is required}"

# 面板端口改为 1111，与 InstaCloud 平台配置保持一致
XUI_PORT="${PORT:-${XUI_PORT:-1111}}"

# ===== 准备 /data 持久化目录 =====
mkdir -p /data
chown -R root:root /data 2>/dev/null || true

# ===== 强制 3x-ui 面板端口为 1111（写入其数据库配置）=====
/app/x-ui setting -port "${XUI_PORT}" >/dev/null 2>&1 || true

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

# ===== 生成 komari-agent 的 supervisord 配置 =====
cat > /etc/supervisor/conf.d/komari.conf <<EOF
[program:komari-agent]
command=/usr/local/bin/komari-agent
    -e "${AGENT_ENDPOINT}"
    --auto-discovery "${AGENT_AUTO_DISCOVERY_KEY}"
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
