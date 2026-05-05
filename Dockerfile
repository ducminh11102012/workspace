FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Ho_Chi_Minh

# ── 1. Cài tool host ──────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    bash \
    tzdata \
    procps \
    novnc \
    websockify \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# ── 2. Clone freeroot vào /data ───────────────────────────────────────────────
RUN mkdir -p /data && \
    git clone https://github.com/foxytouxxx/freeroot.git /data/freeroot

# ── 3. Chạy noninteractive.sh lần đầu: tự download rootfs → vào proot → cài app
# Pipe toàn bộ lệnh cần cài vào stdin, script sẽ chạy chúng bên trong proot
RUN cd /data/freeroot && HOME=/data bash noninteractive.sh << 'EOF'
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    dbus-x11 \
    tigervnc-standalone-server \
    tigervnc-common
apt-get clean
rm -rf /var/lib/apt/lists/*
mkdir -p ~/.vnc
printf 'password\npassword\nn\n' | vncpasswd
printf '#!/bin/bash\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexec startxfce4\n' > ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup
EOF

# ── 4. Entrypoint: spawn 2 process song song ─────────────────────────────────
# - Process 1: noninteractive.sh detect rootfs có sẵn → vào proot → start vncserver
# - Process 2: websockify noVNC bridge 7860 → 5900
RUN cat > /entrypoint.sh << 'EOF'
#!/bin/bash
set -e

echo "[*] Spawning proot environment + VNC..."
cd /data/freeroot && HOME=/data bash noninteractive.sh << 'PROOT_CMD' &
vncserver :1 -geometry 1280x720 -depth 24 -localhost no
tail -f /dev/null
PROOT_CMD

echo "[*] Waiting for VNC server to be ready..."
sleep 6

echo "[*] Spawning noVNC on port 7860..."
websockify --web=/usr/share/novnc 7860 localhost:5900 &

echo "========================================"
echo " Desktop ready!"
echo " -> http://localhost:7860/vnc.html"
echo " -> VNC port: 5900  |  password: password"
echo "========================================"

wait
EOF
chmod +x /entrypoint.sh

EXPOSE 5900 7860

ENTRYPOINT ["/entrypoint.sh"]
