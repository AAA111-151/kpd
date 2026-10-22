FROM ghcr.io/mhsanaei/3x-ui:latest

# 让证书目录也落在 /etc/x-ui 下，实现单卷持久化
RUN rm -rf /root/cert \
    && mkdir -p /etc/x-ui/cert \
    && ln -sfn /etc/x-ui/cert /root/cert

ENV XUI_DB_FOLDER=/etc/x-ui \
    XUI_LOG_FOLDER=/dev/null
