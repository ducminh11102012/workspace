#!/bin/bash

# --- PHẦN 1: CÀI ĐẶT (Chạy trong bước RUN của Docker) ---
if [ "$1" == "build" ]; then
    apt-get update
    # Cài đặt mọi thứ nhạy cảm ở đây
    apt-get install -y xvfb x11vnc dbus-x11 kde-plasma-desktop dolphin wine64 wine32 python3-pip sudo > /dev/null 2>&1
    pip3 install websockify > /dev/null 2>&1
    git clone --depth 1 https://github.com/novnc/noVNC.git /home/user/noVNC > /dev/null 2>&1
    exit 0
fi

# --- PHẦN 2: KHỞI CHẠY (Chạy trong bước CMD của Docker) ---
if [ "$1" == "start" ]; then
    # Cấp quyền tối thượng cho user và data
    sudo chown -R 1000:1000 /data /home/user 2>/dev/null
    sudo chmod -R 777 /data /tmp

    # Liên kết dữ liệu vĩnh viễn vào Bucket /data
    DIRS=".wine .config .local Desktop Downloads"
    for d in $DIRS; do
        mkdir -p /data/$d
        [ "$(ls -A /home/user/$d 2>/dev/null)" ] && [ ! "$(ls -A /data/$d 2>/dev/null)" ] && cp -r /home/user/$d/. /data/$d/
        rm -rf /home/user/$d && ln -s /data/$d /home/user/$d
    done

    # Khởi chạy môi trường đồ họa
    rm -rf /tmp/.X*-lock /tmp/.X11-unix
    Xvfb :1 -screen 0 1920x1080x24+32 +extension RANDR &
    sleep 2
    dbus-launch --exit-with-session startplasma-x11 > /dev/null 2>&1 &
    x11vnc -display :1 -nopw -forever -shared -rfbport 5900 &

    # Mở cổng noVNC
    python3 -m websockify --web /home/user/noVNC 7860 localhost:5900
fi
