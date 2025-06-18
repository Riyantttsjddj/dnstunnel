#!/bin/bash

# === Konfigurasi ===
IODINE_DOMAIN="dns.riyan123.ip-ddns.com"
IODINE_PASSWORD="saputra456"
IODINE_IP="10.0.0.1"
IODINE_BIN="/usr/sbin/iodined"
LOG_FILE="/var/log/iodine/iodine.log"
SERVICE_FILE="/etc/systemd/system/iodine-server.service"
WAN_IFACE=$(ip route get 8.8.8.8 | awk '{print $5; exit}')

echo "🛠️ Menginstal iodine & iptables-persistent..."
apt update -y && apt install -y iodine iptables-persistent

echo "📡 Mengaktifkan IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i '/^#net.ipv4.ip_forward=1/c\net.ipv4.ip_forward=1' /etc/sysctl.conf
sysctl -p

echo "🧹 Menghapus konfigurasi lama (jika ada)..."
rm -f "$SERVICE_FILE"
rm -f "$LOG_FILE"

echo "📁 Membuat folder log jika belum ada..."
mkdir -p "$(dirname $LOG_FILE)"

echo "🔧 Konfigurasi iptables NAT..."
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o $WAN_IFACE -j MASQUERADE
iptables -A FORWARD -s 10.0.0.0/24 -j ACCEPT

echo "💾 Menyimpan iptables rules..."
netfilter-persistent save

echo "📝 Membuat systemd service iodine-server..."
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Iodine DNS Tunnel Server
After=network.target

[Service]
ExecStart=$IODINE_BIN -f -P $IODINE_PASSWORD $IODINE_IP $IODINE_DOMAIN
Restart=always
RestartSec=5
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE

[Install]
WantedBy=multi-user.target
EOF

echo "🔥 Membuka port 53 UDP..."
ufw allow 53/udp 2>/dev/null || true

echo "✅ Mengaktifkan dan menjalankan iodine-server.service..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable iodine-server
systemctl restart iodine-server

echo "🎉 Selesai! Iodine server berjalan di VPS kamu!"
echo "🌐 Domain: $IODINE_DOMAIN"
echo "🔑 Password: $IODINE_PASSWORD"
echo "📄 Log file: $LOG_FILE"
