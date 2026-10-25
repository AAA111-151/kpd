#!/bin/sh
set -e

# ===== 必填变量检查（使用 Komari Agent 官方变量名）=====
: "${TUNNEL_TOKEN:?TUNNEL_TOKEN is required}"
: "${AGENT_ENDPOINT:?AGENT_ENDPOINT is required}"
: "${AGENT_AUTO_DISCOVERY_KEY:?AGENT_AUTO_DISCOVERY_KEY is required}"

# 平台要求应用监听 :2053，这里把 x-ui 面板端口固定为 2053
XUI_PORT="${XUI_PORT:-2053}"

# ===== 准备 /data 持久化目录 =====
mkdir -p /data
chown -R root:root /data 2>/dev/null || true

# ===== 强制 3x-ui 面板端口为 2053（写入其数据库配置）=====
# 3x-ui 支持 `x-ui setting -port <port>`；首次运行数据库尚未创建时可能失败，忽略即可，
# 因为后续 x-ui 启动时也会读取 XUI_PORT 环境变量。
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
