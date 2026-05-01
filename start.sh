#!/bin/bash
set -e # Dừng lại ngay nếu có lệnh bị lỗi để dễ debug

# Nạp PATH chuẩn
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

echo "--- [1/3] Đang cài đặt Core Components ---"
sudo apt-get update

# Quan trọng: Không dùng > /dev/null để theo dõi tiến trình cài đặt
# Thêm DEBIAN_FRONTEND=noninteractive để tránh bị hỏi linh tinh
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    xvfb \
    x11vnc \
    dbus-x11 \
    kde-plasma-desktop \
    konsole \
    dolphin \
    wine64 \
    python3-pip \
    git \
    python3

echo "--- [2/3] Cấu hình Dữ liệu & noVNC ---"
sudo chown -R 1000:1000 /data /home/user 2>/dev/null

# Cài đặt websockify cho python3
sudo pip3 install websockify

if [ ! -d "$HOME/noVNC" ]; then
    git clone --depth 1 https://github.com/novnc/noVNC.git $HOME/noVNC
fi

# Link dữ liệu sang Bucket
DIRS=".wine .config .local Desktop Downloads"
for d in $DIRS; do
    mkdir -p /data/$d
    [ "$(ls -A $HOME/$d 2>/dev/null)" ] && [ ! "$(ls -A /data/$d 2>/dev/null)" ] && cp -r $HOME/$d/. /data/$d/
    rm -rf $HOME/$d && ln -s /data/$d $HOME/$d
done

echo "--- [3/3] Khởi động Giao diện ---"
sudo rm -rf /tmp/.X*-lock /tmp/.X11-unix
Xvfb :1 -screen 0 1920x1080x24+32 &
sleep 5

# Khởi chạy KDE (Dùng sudo -u user để đảm bảo đúng quyền nếu cần)
dbus-launch --exit-with-session startplasma-x11 > /dev/null 2>&1 &
x11vnc -display :1 -nopw -forever -shared -rfbport 5900 &

echo "--- HỆ THỐNG ĐÃ SẴN SÀNG TẠI CỔNG 7860 ---"
python3 -m websockify --web $HOME/noVNC 7860 localhost:5900
