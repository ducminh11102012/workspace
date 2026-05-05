#!/bin/bash

set -e

echo "[+] Base install..."

apt-get update && apt-get install -y \
    proot wget curl git tar xz-utils \
    novnc websockify \
    || true

ROOTFS=/data/rootfs
mkdir -p $ROOTFS

# =========================
# ROOTFS DOWNLOAD
# =========================
if [ ! -f /data/rootfs/.ready ]; then
    echo "[+] Downloading Ubuntu rootfs..."

    curl -L -o /tmp/rootfs.tar.gz \
    https://partner-images.canonical.com/core/jammy/current/ubuntu-jammy-core-cloudimg-amd64-root.tar.gz

    tar -xzf /tmp/rootfs.tar.gz -C $ROOTFS
    rm /tmp/rootfs.tar.gz

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
# INSTALL XFCE (SAFE CORE + DBUS FIX)
# =========================
echo "[+] Installing XFCE core + DBUS..."

proot -0 -r $ROOTFS /bin/bash -c "
set -e

export DEBIAN_FRONTEND=noninteractive

# FIX dpkg state trước
dpkg --configure -a || true
apt -f install -y || true

apt update

apt install -y \
    xfce4-session \
    xfce4-panel \
    xfce4-settings \
    xfwm4 \
    xfdesktop4 \
    thunar \
    dbus \
    dbus-x11 \
    x11vnc \
    xvfb \
    --no-install-recommends

apt clean
"

# =========================
# START SCRIPT
# =========================
cat > /start.sh <<'EOF'
#!/bin/bash

set -e

ROOTFS=/data/rootfs
export DISPLAY=:1

echo "[+] Starting XFCE + DBUS fixed stack..."

proot -0 -r $ROOTFS /bin/bash -c "
set -e

export DISPLAY=:1

# ===== DBUS FIX (IMPORTANT) =====
eval \$(dbus-launch --sh-syntax)

# ===== X SERVER =====
Xvfb :1 -screen 0 1280x720x16 &
sleep 2

# ===== XFCE CORE =====
xfwm4 &
xfdesktop &
xfce4-panel &

sleep 2

# ===== VNC =====
x11vnc -display :1 -forever -nopw -rfbport 5900 &
"

sleep 3

echo "[+] Starting noVNC (APT)..."

NOVNC=/usr/share/novnc/utils/novnc_proxy

$NOVNC \
    --vnc localhost:5900 \
    --listen 7860

wait
EOF

chmod +x /start.sh

echo "[+] DONE"
echo "[+] Run: bash /start.sh"
