#!/bin/bash
# Nạp PATH để nhận diện lệnh hệ thống
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

echo "--- [1/3] Đang cài đặt Windows Subsystem (Wine) & Desktop (KDE) ---"
# Cài đặt lặng lẽ nhưng đầy đủ
sudo apt-get update
sudo apt-get install -y xvfb x11vnc dbus-x11 kde-plasma-desktop konsole dolphin wine64 wine32 python3-pip git > /dev/null 2>&1

echo "--- [2/3] Cấu hình Persistence (Dữ liệu vĩnh viễn) ---"
sudo chown -R 1000:1000 /data /home/user 2>/dev/null

# Cài đặt noVNC nếu chưa tồn tại
if [ ! -d "$HOME/noVNC" ]; then
    git clone --depth 1 https://github.com/novnc/noVNC.git $HOME/noVNC
    sudo pip3 install websockify
fi

# Liên kết các thư mục quan trọng vào Bucket /data để không mất dữ liệu
DIRS=".wine .config .local Desktop Downloads"
for d in $DIRS; do
    mkdir -p /data/$d
    # Nếu trong Home có sẵn dữ liệu thì đồng bộ qua trước khi link
    [ "$(ls -A $HOME/$d 2>/dev/null)" ] && [ ! "$(ls -A /data/$d 2>/dev/null)" ] && cp -r $HOME/$d/. /data/$d/
    rm -rf $HOME/$d && ln -s /data/$d $HOME/$d
done

echo "--- [3/3] Khởi động Giao diện Đồ họa ---"
# Dọn dẹp session cũ
sudo rm -rf /tmp/.X*-lock /tmp/.X11-unix

# Chạy màn hình ảo
Xvfb :1 -screen 0 1920x1080x24+32 +extension RANDR &
sleep 2

# Khởi động KDE Plasma
dbus-launch --exit-with-session startplasma-x11 > /dev/null 2>&1 &

# Chạy VNC Server
x11vnc -display :1 -nopw -forever -shared -rfbport 5900 &

echo "--- HỆ THỐNG ĐÃ SẴN SÀNG TẠI CỔNG 7860 ---"
# Bridge VNC sang Web (noVNC)
python3 -m websockify --web $HOME/noVNC 7860 localhost:5900
