#!/bin/bash

set -e

ROOTFS=/data/rootfs
mkdir -p $ROOTFS

echo "[+] Downloading system image..."

if [ ! -f /data/rootfs/.ready ]; then
    wget -O /tmp/rootfs.tar.gz \
    https://partner-images.canonical.com/core/jammy/current/ubuntu-jammy-core-cloudimg-amd64-root.tar.gz

    tar -xzf /tmp/rootfs.tar.gz -C $ROOTFS
    rm /tmp/rootfs.tar.gz

    touch /data/rootfs/.ready
fi

echo "[+] Installing inside rootfs..."

proot -0 -r $ROOTFS /bin/bash -c "
apt update &&
apt install -y \
    plasma-desktop \
    plasma-workspace \
    dbus-x11 \
    x11vnc \
    xvfb \
    --no-install-recommends &&
apt clean
"

echo "[+] Creating runtime start script..."

cat > /data/start.sh <<'EOF'
#!/bin/bash

export DISPLAY=:1
export KDE_NO_COMPOSITING=1

Xvfb :1 -screen 0 1024x600x16 &
sleep 2

dbus-launch --exit-with-session startplasma-x11 &

x11vnc -display :1 -forever -nopw -rfbport 5900 &

wait
EOF

chmod +x /data/start.sh

echo "[+] Setup complete"
