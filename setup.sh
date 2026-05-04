#!/bin/bash

set -e

echo "[+] Installing base tools..."

apt-get update && apt-get install -y \
    proot wget curl git tar xz-utils \
    || true

# =========================
# 0. HOST - INSTALL noVNC VIA APT
# =========================
echo "[+] Installing noVNC (APT)..."

apt-get update && apt-get install -y \
    novnc \
    websockify \
    || true

# =========================
# 1. ROOTFS
# =========================
ROOTFS=/data/rootfs
mkdir -p $ROOTFS

if [ ! -f /data/rootfs/.ready ]; then
    echo "[+] Downloading Ubuntu rootfs..."

    curl -L -o /tmp/rootfs.tar.gz \
    https://partner-images.canonical.com/core/jammy/current/ubuntu-jammy-core-cloudimg-amd64-root.tar.gz

    tar -xzf /tmp/rootfs.tar.gz -C $ROOTFS
    rm /tmp/rootfs.tar.gz

    echo "[+] Fixing network..."

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
# 2. INSTALL XFCE + VNC
# =========================
echo "[+] Installing XFCE inside ROOTFS..."

proot -0 -r $ROOTFS /bin/bash -c "
set -e

dpkg --configure -a || true
apt -f install -y || true

apt update

apt install -y \
    xfce4 \
    xfce4-goodies \
    x11vnc \
    xvfb \
    dbus-x11 \
    git curl wget sudo \
    --no-install-recommends

apt clean
"

# =========================
# 3. START SCRIPT
# =========================
cat > /start.sh <<'EOF'
#!/bin/bash

set -e

ROOTFS=/data/rootfs
export DISPLAY=:1

echo "[+] Starting XFCE inside ROOTFS..."

proot -0 -r $ROOTFS /bin/bash -c "
export DISPLAY=:1

Xvfb :1 -screen 0 1024x600x16 &
sleep 2

startxfce4 &
sleep 2

x11vnc -display :1 -forever -nopw -rfbport 5900 &
"

sleep 3

echo "[+] Starting noVNC (APT version)..."

# Debian/Ubuntu path
NOVNC=/usr/share/novnc/utils/novnc_proxy

if [ ! -f $NOVNC ]; then
    echo "[!] noVNC not found via apt"
    exit 1
fi

$NOVNC \
    --vnc localhost:5900 \
    --listen 7860

wait
EOF

chmod +x /start.sh

echo "[+] Setup complete"
echo "[+] Run: bash /start.sh"
