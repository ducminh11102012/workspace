FROM msjpq/firefox-vnc:latest

USER root

# --- [1] CÀI ĐẶT WINE & DEPENDENCIES ---
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wine64 wine32 winetricks sudo socat curl wget cabextract \
    libvulkan1 libvulkan1:i386 libwine:i386 \
    fonts-liberation zenity x11-apps xvfb && \
    echo "ALL ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- [2] CÀI COMPONENTS TRONG BUILD (FIX LỖI CHDIR) ---
# Thiết lập WINEPREFIX về thư mục root để tránh lỗi /config
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win64
ENV WINEDEBUG=-all

RUN mkdir -p /root/.wine && \
    # Sử dụng Xvfb để tạo màn hình ảo tạm thời cho Wine khởi tạo trong lúc build
    Xvfb :99 -screen 0 1024x768x16 & \
    export DISPLAY=:99 && \
    sleep 5 && \
    wine wineboot --init && \
    sleep 10 && \
    # Cài đặt các thành phần quan trọng (Dùng bản dotnet nhẹ hơn để tăng tỉ lệ thành công)
    winetricks -q corefonts && \
    winetricks -q vcrun2015 && \
    # Dotnet 4.8 nặng và dễ lỗi, mình dùng dotnet40 hoặc 45 trước để kiểm tra, 
    # Nếu bạn cần 4.8 hãy giữ nguyên nhưng chuẩn bị tinh thần build lâu
    winetricks -q dotnet48 && \
    # Dọn dẹp sau khi cài
    pkill Xvfb

# --- [3] BIẾN MÔI TRƯỜNG VẬN HÀNH ---
ENV PUID=0
ENV PGID=0
ENV ROOT_PASSWORD=Binhminh12
ENV NGINX_PORT=7860
ENV SCR_WIDTH=1920
ENV SCR_HEIGHT=1080
ENV VNC_RESIZE=remote

# --- [4] ENTRYPOINT (SOCAT + PERSISTENT) ---
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "--- [1/2] Đang mount dữ liệu ---"\n\
sudo mkdir -p /data && sudo chmod -R 777 /data\n\
# Lưu ý: Không link .wine nếu bạn đã cài component ở bước RUN \n\
# vì nó sẽ đè lên bộ thư viện bạn vừa cài. \n\
# Chỉ link Desktop, Downloads và Mozilla.\n\
DIRS="Desktop Downloads Documents .mozilla"\n\
for d in $DIRS; do\n\
    mkdir -p /data/$d\n\
    rm -rf /root/$d\n\
    ln -s /data/$d /root/$d\n\
done\n\
\n\
echo "--- [2/2] Chạy Bridge 7860->8080 & Start System ---"\n\
socat TCP-LISTEN:7860,fork,reuseaddr TCP:127.0.0.1:8080 &\n\
\n\
exec /init' > /usr/local/bin/entrypoint.sh && \
chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /root
EXPOSE 7860

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
