#!/bin/bash

# Nạp lại đường dẫn hệ thống một lần nữa cho chắc
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# --- CẤP QUYỀN TRUY CẬP ---
sudo chown -R 1000:1000 /home/user /data 2>/dev/null
sudo chmod -R 777 /tmp

# --- LIÊN KẾT DỮ LIỆU ---
DIRS=".wine .config .local Desktop Downloads"
for d in $DIRS; do
    mkdir -p /data/$d
    [ "$(ls -A /home/user/$d 2>/dev/null)" ] && [ ! "$(ls -A /data/$d 2>/dev/null)" ] && sudo cp -r /home/user/$d/. /data/$d/
    rm -rf /home/user/$d && ln -s /data/$d /home/user/$d
done

# --- KHỞI CHẠY VỚI ĐƯỜNG DẪN TUYỆT ĐỐI ---
sudo rm -rf /tmp/.X*-lock /tmp/.X11-unix

# Sử dụng 'command -v' để kiểm tra trước hoặc dùng đường dẫn trực tiếp
/usr/bin/Xvfb :1 -screen 0 1920x1080x24+32 +extension RANDR &
sleep 2

/usr/bin/dbus-launch --exit-with-session /usr/bin/startplasma-x11 > /dev/null 2>&1 &
/usr/bin/x11vnc -display :1 -nopw -forever -shared -rfbport 5900 &

# Chạy noVNC
/usr/bin/python3 -m websockify --web /home/user/noVNC 7860 localhost:5900
