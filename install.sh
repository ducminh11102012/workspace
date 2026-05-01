#!/bin/bash
# Đang chạy với quyền ROOT từ lệnh RUN
apt-get update
# Cài đặt các gói cốt lõi
apt-get install -y xvfb x11vnc dbus-x11 kde-plasma-desktop dolphin konsole wine64 wine32 winetricks python3-pip sudo > /dev/null 2>&1

# Cài đặt giao diện web noVNC
pip3 install websockify > /dev/null 2>&1
git clone --depth 1 https://github.com/novnc/noVNC.git /home/user/noVNC > /dev/null 2>&1
cp /home/user/noVNC/vnc.html /home/user/noVNC/index.html

# Dọn dẹp rác hệ thống
apt-get clean && rm -rf /var/lib/apt/lists/*
echo "Setup complete!"
