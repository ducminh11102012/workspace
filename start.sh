#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

echo "--- [START] Đang chuẩn bị dữ liệu vĩnh viễn ---"
# Cấp lại quyền sở hữu cho chắc chắn
sudo chown -R 1000:1000 /data /home/user 2>/dev/null

# Link các thư mục quan trọng vào Bucket /data
DIRS=".wine .config .local Desktop Downloads"
for d in $DIRS; do
    mkdir -p /data/$d
    # Đồng bộ dữ liệu cũ sang data nếu data mới tinh
    [ "$(ls -A $HOME/$d 2>/dev/null)" ] && [ ! "$(ls -A /data/$d 2>/dev/null)" ] && cp -r $HOME/$d/. /data/$d/
    rm -rf $HOME/$d && ln -s /data/$d $HOME/$d
done

echo "--- [START] Kích hoạt màn hình ảo Plasma ---"
sudo rm -rf /tmp/.X*-lock /tmp/.X11-unix
Xvfb :1 -screen 0 1920x1080x24+32 &
sleep 2

# Chạy KDE và VNC
dbus-launch --exit-with-session startplasma-x11 > /dev/null 2>&1 &
x11vnc -display :1 -nopw -forever -shared -rfbport 5900 &

echo "--- [SUCCESS] Truy cập cổng 7860 để sử dụng ---"
python3 -m websockify --web $HOME/noVNC 7860 localhost:5900
