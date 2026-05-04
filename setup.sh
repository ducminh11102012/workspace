#!/bin/bash

set -e

echo "[+] Installing base tools..."

apt-get update && apt-get install -y \
    proot wget curl git tar xz-utils \
    || true

ROOTFS=/data/rootfs
mkdir -p $ROOTFS

# =========================
# 0. CLONE NOVNC EARLY (HOST LAYER)
# =========================
echo "[+] Preparing HOST tools (noVNC)..."

mkdir -p /opt

if [ ! -d /opt/noVNC ]; then
    git clone https://github.com/novnc/noVNC /opt/noVNC
fi

if [ ! -d /opt/websockify ]; then
    git clone https://github.com/novnc/websockify /opt/websockify
fi

# =========================
# 1. DOWNLOAD ROOTFS
# =========================
if [ ! -f /data/rootfs/.ready ]; then
    echo "[+] Downloading Ubuntu rootfs..."

    curl -L -o /tmp/rootfs.tar.gz \
    https://partner-images.canonical.com/core/jammy/current/ubuntu-jammy-core-cloudimg-amd64-root.tar.gz

    tar -xzf /tmp/rootfs.tar.gz -C $ROOTFS
    rm /tmp/rootfs.tar.gz

    echo "[+] Fixing network inside rootfs..."

    mkdir -p $ROOTFS/etc/apt/apt.conf.d

    cat > $ROOTFS/etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

    cat > $ROOTFS/etc/apt/apt.conf.d/99force-ipv4 <<EOF
Acquire::ForceIPv4 "true";
EOF

    touch /data/rootfs/.ready
fi

# =========================
# 2. INSTALL DESKTOP IN ROOTFS
# =========================
echo "[+] Installing desktop inside rootfs..."

proot -0 -r $ROOTFS /bin/bash -c "
set -e

apt update

apt install -y \
    plasma-desktop \
    dbus-x11 \
    x11vnc \
    xvfb \
    git curl wget \
    --no-install-recommends

apt clean
"

# =========================
# 3. START SCRIPT (HOST)
# =========================
cat > /start.sh <<'EOF'
#!/bin/bash

set -e

ROOTFS=/data/rootfs
export DISPLAY=:1

echo "[+] Booting desktop inside ROOTFS..."

proot -0 -r $ROOTFS /bin/bash -c "
export DISPLAY=:1

echo '[+] Starting Xvfb...'
Xvfb :1 -screen 0 1024x600x16 &

sleep 2

echo '[+] Starting KDE session...'
dbus-launch --exit-with-session startplasma-x11 &

echo '[+] Starting VNC server...'
x11vnc -display :1 -forever -nopw -rfbport 5900 &

echo '[+] Desktop running inside ROOTFS'
"

sleep 3

echo "[+] Starting noVNC on HOST..."

cd /opt/noVNC

./utils/novnc_proxy \
    --vnc localhost:5900 \
    --listen 7860

wait
EOF

chmod +x /start.sh

echo "[+] Setup complete"
echo "[+] Run: bash /start.sh"
