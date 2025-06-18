#!/bin/bash

# === Konfigurasi ===
IODINE_DOMAIN="dns.riyan123.ip-ddns.com"
IODINE_PASSWORD="saputra456"
IODINE_IP="10.0.0.1"
IODINE_BIN="/usr/sbin/iodined"
LOG_FILE="/var/log/iodine.log"
SERVICE_FILE="/etc/systemd/system/iodine-server.service"
WAN_IFACE=$(ip route | grep default | awk '{print $5}')

echo "🛠️ Menginstal iodine..."
apt update -y && apt install iodine -y

echo "📡 Mengaktifkan IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i '/^#net.ipv4.ip_forward=1/c\net.ipv4.ip_forward=1' /etc/sysctl.conf
sysctl -p

echo "🔧 Konfigurasi iptables NAT..."
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o $WAN_IFACE -j MASQUERADE
iptables -A FORWARD -s 10.0.0.0/24 -j ACCEPT
iptables-save > /etc/iptables.rules

# Auto load iptables saat boot
cat > /etc/network/if-pre-up.d/iptablesload <<EOF
#!/bin/sh
iptables-restore < /etc/iptables.rules
EOF
chmod +x /etc/network/if-pre-up.d/iptablesload

echo "📝 Membuat systemd service iodine-server..."
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Iodine DNS Tunnel Server
After=network.target

[Service]
ExecStart=$IODINE_BIN -f -c -P $IODINE_PASSWORD $IODINE_IP $IODINE_DOMAIN
Restart=always
RestartSec=5
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE

[Install]
WantedBy=multi-user.target
EOF

echo "🔥 Membuka port 53 UDP..."
ufw allow 53/udp 2>/dev/null || true

# Aktifkan service
echo "✅ Mengaktifkan dan menjalankan iodine-server.service..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable iodine-server
systemctl restart iodine-server

echo "🎉 Selesai! Iodine server berjalan di VPS kamu!"
echo "🌐 Domain: $IODINE_DOMAIN"
echo "🔑 Password: $IODINE_PASSWORD"
echo "📄 Log file: $LOG_FILE"
