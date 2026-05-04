#!/bin/bash

set -e

echo "[+] Installing base tools..."

apt-get update && apt-get install -y \
    proot wget curl git tar xz-utils \
    || true

ROOTFS=/data/rootfs
mkdir -p $ROOTFS

# =========================
# 1. Download rootfs
# =========================
if [ ! -f /data/rootfs/.ready ]; then
    echo "[+] Downloading Ubuntu rootfs..."

    curl -L -o /tmp/rootfs.tar.gz \
    https://partner-images.canonical.com/core/jammy/current/ubuntu-jammy-core-cloudimg-amd64-root.tar.gz

    tar -xzf /tmp/rootfs.tar.gz -C $ROOTFS
    rm /tmp/rootfs.tar.gz

    touch /data/rootfs/.ready
fi

# =========================
# 2. Install everything inside rootfs
# =========================
echo "[+] Installing inside rootfs..."

proot -0 -r $ROOTFS /bin/bash -c "
apt update &&
apt install -y \
    plasma-desktop \
    plasma-workspace \
    dbus-x11 \
    x11vnc \
    xvfb \
    git curl wget \
    --no-install-recommends &&
apt clean
"

# =========================
# 3. Install noVNC inside rootfs
# =========================
proot -0 -r $ROOTFS /bin/bash -c "
mkdir -p /opt &&
cd /opt &&
git clone https://github.com/novnc/noVNC &&
git clone https://github.com/novnc/websockify
"

# =========================
# 4. Create launcher
# =========================
cat > /start.sh <<'EOF'
#!/bin/bash

export DISPLAY=:1
export KDE_NO_COMPOSITING=1

echo "[+] Starting Xvfb..."
Xvfb :1 -screen 0 1024x600x16 &

sleep 2

echo "[+] Starting desktop session..."
dbus-launch --exit-with-session startplasma-x11 &

echo "[+] Starting VNC..."
x11vnc -display :1 -forever -nopw -rfbport 5900 &

echo "[+] Starting noVNC..."
cd /opt/noVNC
./utils/novnc_proxy --vnc localhost:5900 --listen 7860

wait
EOF

chmod +x /start.sh

echo "[+] Setup complete"
