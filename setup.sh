# syntax=docker/dockerfile:1
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Ho_Chi_Minh

# ── 1. Dependencies ───────────────────────────────────────────────────────────
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

# ── 3. Cài XFCE + VNC bên trong proot lúc build ──────────────────────────────
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
' > /data/bootstrap.sh && chmod +x /data/bootstrap.sh

RUN cd /data/freeroot && HOME=/data bash noninteractive.sh < /data/bootstrap.sh

# ── 4. Entrypoint ─────────────────────────────────────────────────────────────
RUN printf '#!/bin/bash\n\
set -e\n\
\n\
# Start desktop service\n\
echo "vncserver :1 -rfbport 1538 -geometry 1280x720 -depth 24 -localhost no && tail -f /dev/null" \\\n\
    | (cd /data/freeroot && HOME=/data bash noninteractive.sh) > /dev/null 2>&1 &\n\
\n\
sleep 6\n\
\n\
# Start web service\n\
websockify --web=/usr/share/novnc 7860 localhost:1538 > /dev/null 2>&1 &\n\
\n\
echo "Done!"\n\
\n\
wait\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 7860

ENTRYPOINT ["/entrypoint.sh"]
