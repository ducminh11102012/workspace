#!/bin/bash
set -e
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

echo "--- [BUILD] Kích hoạt kiến trúc 32-bit cho Wine ---"
# Đây là lệnh then chốt để sửa lỗi "no installation candidate"
dpkg --add-architecture i386
apt-get update

echo "--- [BUILD] Đang cài đặt hệ thống đồ họa và Wine ---"
# Cài đặt các gói cần thiết
apt-get install -y \
    xvfb x11vnc dbus-x11 kde-plasma-desktop \
    konsole dolphin wine64 wine32 python3-pip git python3 \
    coreutils wget

# Cấu hình noVNC
echo "--- [BUILD] Cấu hình noVNC ---"
pip3 install websockify
if [ ! -d "/home/user/noVNC" ]; then
    git clone --depth 1 https://github.com/novnc/noVNC.git /home/user/noVNC
fi

# Dọn dẹp để giảm dung lượng Image
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "--- [BUILD] Hoàn tất cài đặt ---"
