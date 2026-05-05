# syntax=docker/dockerfile:1
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

# ── 3. Tạo script cài app để chạy bên trong proot ────────────────────────────
RUN printf '#!/bin/bash\n\
export DEBIAN_FRONTEND=noninteractive\n\
apt-get update -y\n\
apt-get install -y xfce4 xfce4-goodies xfce4-terminal dbus-x11 tigervnc-standalone-server tigervnc-common\n\
apt-get clean\n\
rm -rf /var/lib/apt/lists/*\n\
mkdir -p ~/.vnc\n\
printf "password\\npassword\\nn\\n" | vncpasswd\n\
printf "#!/bin/bash\\nunset SESSION_MANAGER\\nunset DBUS_SESSION_BUS_ADDRESS\\nexec startxfce4\\n" > ~/.vnc/xstartup\n\
chmod +x ~/.vnc/xstartup\n\
' > /data/install_desktop.sh && chmod +x /data/install_desktop.sh

# ── 4. Chạy noninteractive.sh: tự download rootfs → vào proot → cài app ──────
RUN cd /data/freeroot && HOME=/data bash noninteractive.sh < /data/install_desktop.sh

# ── 5. Tạo entrypoint ────────────────────────────────────────────────────────
RUN printf '#!/bin/bash\n\
set -e\n\
\n\
echo "[*] Spawning proot environment + VNC..."\n\
echo "vncserver :1 -geometry 1280x720 -depth 24 -localhost no && tail -f /dev/null" \\\n\
    | (cd /data/freeroot && HOME=/data bash noninteractive.sh) &\n\
\n\
echo "[*] Waiting for VNC server to be ready..."\n\
sleep 6\n\
\n\
echo "[*] Spawning noVNC on port 7860..."\n\
websockify --web=/usr/share/novnc 7860 localhost:5900 &\n\
\n\
echo "========================================"\n\
echo " Desktop ready!"\n\
echo " -> http://localhost:7860/vnc.html"\n\
echo " -> VNC port: 5900  |  password: password"\n\
echo "========================================"\n\
\n\
wait\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 5900 7860

ENTRYPOINT ["/entrypoint.sh"]
