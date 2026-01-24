#!/bin/bash
# ================================================================
# 🚀 Optimized: Windows 11 (64GB RAM / 16 Cores) for Codespaces
# ================================================================

set -e

echo "=== 🔧 Menjalankan sebagai root ==="
if [ "$EUID" -ne 0 ]; then
  echo "Script ini butuh akses root. Jalankan dengan: sudo bash rdp.sh"
  exit 1
fi

echo
echo "=== 📦 Update & Install Docker Compose ==="
apt update -y && apt install docker-compose -y

systemctl enable docker
systemctl start docker

echo
echo "=== 📂 Membuat direktori kerja dockercom ==="
mkdir -p /root/dockercom
cd /root/dockercom

echo
echo "=== 🧾 Membuat file windows.yml (Optimized for 64GB) ==="
cat > windows.yml <<'EOF'
version: "3.9"
services:
  windows:
    image: dockurr/windows
    container_name: windows
    environment:
      VERSION: "11"
      USERNAME: "MASTER"
      PASSWORD: "admin@123"
      RAM_SIZE: "60G"
      CPU_CORES: "16"
    devices:
      - /dev/kvm
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    ports:
      - "8006:8006"
      - "3389:3389/tcp"
      - "3389:3389/udp"
    volumes:
      - /tmp/windows-storage:/storage
    restart: always
    stop_grace_period: 2m
EOF

echo
echo "=== 🚀 Menjalankan Windows 11 container ==="
docker-compose -f windows.yml up -d

echo
echo "=== ☁️ Instalasi Cloudflare Tunnel ==="
if [ ! -f "/usr/local/bin/cloudflared" ]; then
  wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
  chmod +x /usr/local/bin/cloudflared
fi

echo
echo "=== 🌍 Membuat tunnel publik ==="
# Clear old logs
> /var/log/cloudflared_web.log
> /var/log/cloudflared_rdp.log

nohup cloudflared tunnel --url http://localhost:8006 > /var/log/cloudflared_web.log 2>&1 &
nohup cloudflared tunnel --url tcp://localhost:3389 > /var/log/cloudflared_rdp.log 2>&1 &

echo "Waiting for Cloudflare links..."
sleep 10

CF_WEB=$(grep -o "https://[a-zA-Z0-9.-]*\.trycloudflare\.com" /var/log/cloudflared_web.log | head -n 1)
CF_RDP=$(grep -o "tcp://[a-zA-Z0-9.-]*\.trycloudflare\.com:[0-9]*" /var/log/cloudflared_rdp.log | head -n 1)

echo "=============================================="
echo "🌍 Web Console: ${CF_WEB:-'Link not ready, check logs'}"
echo "🖥️  RDP Address: ${CF_RDP:-'Link not ready, check logs'}"
echo "=============================================="
echo "🔑 User: MASTER | Pass: admin@123"
echo "=============================================="echo "  docker logs -f windows"
echo
echo "Untuk melihat link Cloudflare:"
echo "  grep 'trycloudflare' /var/log/cloudflared_*.log"
echo
echo "=============================================="
