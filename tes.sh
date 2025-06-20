#!/bin/bash

# Auto Setup SSH + Stunnel Port 80 - Kamuflase Bug Axis Game (Freenet)
# by ChatGPT - Kamuflase agar terlihat seperti akses api.mobilelegends.com

echo "=== Setup SSH + Stunnel 80 (Kamuflase Bug Host) ==="

# Update & install tools
apt update && apt upgrade -y
apt install -y stunnel4 curl wget net-tools sudo

# Enable stunnel service
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4

# Buat folder & sertifikat TLS palsu
mkdir -p /etc/stunnel
openssl req -new -x509 -days 1095 -nodes \
-out /etc/stunnel/stunnel.pem \
-keyout /etc/stunnel/stunnel.pem \
-subj "/C=ID/ST=Jawa/L=Axis/O=Freenet/CN=api.mobilelegends.com"

# Buat konfigurasi Stunnel port 80
cat > /etc/stunnel/freenet80.conf <<EOF
pid = /var/run/stunnel80.pid
cert = /etc/stunnel/stunnel.pem
client = no
foreground = yes
debug = 0

[bugaxis]
accept = 80
connect = 127.0.0.1:22
EOF

# Buat systemd service agar berjalan otomatis saat boot
cat > /etc/systemd/system/stunnel-freenet80.service <<EOF
[Unit]
Description=Stunnel Freenet Kamuflase Axis Game
After=network.target

[Service]
ExecStart=/usr/bin/stunnel /etc/stunnel/freenet80.conf
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Reload & aktifkan stunnel
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable stunnel-freenet80
systemctl start stunnel-freenet80

# Buat user SSH default
USERNAME="kamuflase"
PASSWORD="mlgratis"
useradd -m -s /bin/bash "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd

# Ambil IP server
IP=$(curl -s ifconfig.me)

# Output hasil setup
echo ""
echo "✅ SETUP BERHASIL - KAMU TERLIHAT SEPERTI AKSES BUG HOST"
echo "-------------------------------------------------------"
echo "SSH Server  : $IP"
echo "SSH Port    : 22"
echo "Stunnel Port: 80 (HTTP kamuflase bug)"
echo "Username    : $USERNAME"
echo "Password    : $PASSWORD"
echo ""
echo "🔒 Payload untuk HTTP Custom:"
echo "GET http://api.mobilelegends.com/ HTTP/1.1[crlf]Host: api.mobilelegends.com[crlf]Connection: Keep-Alive[crlf][crlf]"
echo "Remote Proxy: $IP:80"
echo "SNI         : api.mobilelegends.com (opsional)"
echo ""
echo "Terlihat seolah-olah kamu hanya membuka bug Mobile Legends"
echo "-------------------------------------------------------"
