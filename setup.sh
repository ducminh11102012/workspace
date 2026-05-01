#!/bin/bash
set -e
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

echo "--- [BUILD] Đang cài đặt hệ thống đồ họa và Wine ---"
apt-get update
apt-get install -y \
    xvfb x11vnc dbus-x11 kde-plasma-desktop \
    konsole dolphin wine64 wine32 python3-pip git python3 \
    coreutils wget

# Cài đặt công cụ nền tảng cho noVNC
pip3 install websockify
git clone --depth 1 https://github.com/novnc/noVNC.git /home/user/noVNC

# Dọn dẹp để giảm dung lượng Image
apt-get clean
rm -rf /var/lib/apt/lists/*
echo "--- [BUILD] Hoàn tất cài đặt ---"
