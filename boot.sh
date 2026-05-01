#!/bin/bash
# Chạy với quyền User 1000 nhưng có thể dùng sudo

# 1. Chiếm quyền điều khiển hoàn toàn
sudo chown -R 1000:1000 /data /home/user 2>/dev/null
sudo chmod -R 777 /data /tmp

# 2. Đồng bộ hóa với Bucket /data (Persistence)
DIRS=".wine .config .local Desktop Downloads"
for d in $DIRS; do
    mkdir -p /data/$d
    # Copy dữ liệu ban đầu từ Image sang Bucket nếu Bucket đang trống
    if [ "$(ls -A /home/user/$d 2>/dev/null)" ] && [ ! "$(ls -A /data/$d 2>/dev/null)" ]; then
        cp -r /home/user/$d/. /data/$d/
    fi
    rm -rf /home/user/$d
    ln -s /data/$d /home/user/$d
done

# 3. Khởi chạy màn hình ảo và KDE
rm -rf /tmp/.X*-lock /tmp/.X11-unix
Xvfb :1 -screen 0 1920x1080x24+32 +extension RANDR &
sleep 2
dbus-launch --exit-with-session startplasma-x11 > /dev/null 2>&1 &
x11vnc -display :1 -nopw -forever -shared -rfbport 5900 &

# 4. Mở cổng giao diện Web
python3 -m websockify --web /home/user/noVNC 7860 localhost:5900
