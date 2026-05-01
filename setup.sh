#!/bin/bash
set -e
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

echo "--- [BUILD] Đang cập nhật hệ thống ---"
apt-get update

echo "--- [BUILD] Cài đặt Desktop (KDE) và Wine64 ---"
# Loại bỏ wine32, chỉ giữ lại các gói 64-bit cốt lõi
apt-get install -y \
    xvfb x11vnc dbus-x11 kde-plasma-desktop \
    konsole dolphin wine64 python3-pip git python3 \
    coreutils wget

# Cấu hình noVNC để truy cập qua Web
echo "--- [BUILD] Cài đặt noVNC ---"
pip3 install websockify
if [ ! -d "/home/user/noVNC" ]; then
    git clone --depth 1 https://github.com/novnc/noVNC.git /home/user/noVNC
fi

# Dọn dẹp rác để tối ưu dung lượng Image
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "--- [BUILD] Hoàn tất cài đặt 64-bit! ---"
