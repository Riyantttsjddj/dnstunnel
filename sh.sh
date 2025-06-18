#!/bin/bash

# === Variabel utama ===
DOMAIN="riyan123.ip-ddns.com"
PASSWORD="riyan200324"
TUN_IP="10.0.0.1"
TUN_NET="10.0.0.0/24"
INTERFACE="dns0"

echo "[+] Update & install iodine..."
apt update && apt install -y iodine net-tools iptables

echo "[+] Menjalankan iodine server di background..."
pkill iodined 2>/dev/null
nohup iodined -f -c -P "$PASSWORD" $TUN_IP $DOMAIN > /var/log/iodine.log 2>&1 &

echo "[+] Konfigurasi IP Forwarding dan NAT..."
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -s $TUN_NET -o eth0 -j MASQUERADE

echo "[+] Membuat systemd service untuk iodine..."
cat > /etc/systemd/system/iodine.service << EOF
[Unit]
Description=Iodine DNS Tunnel Server
After=network.target

[Service]
ExecStart=/usr/sbin/iodined -f -c -P "$PASSWORD" $TUN_IP $DOMAIN
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "[+] Mengaktifkan iodine sebagai service..."
systemctl daemon-reload
systemctl enable iodine
systemctl restart iodine

echo "[+] Membuka port 53 UDP..."
iptables -I INPUT -p udp --dport 53 -j ACCEPT

echo ""
echo "✅ Iodine DNS tunnel server berhasil dipasang!"
echo "📡 Domain: $DOMAIN"
echo "🔐 Password: $PASSWORD"
echo "🌐 VPS IP: 8.215.192.205"
echo ""
echo "💡 Gunakan domain ini untuk koneksi: tunnel.$DOMAIN"
