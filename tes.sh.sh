
#!/bin/bash

# Script: Auto Setup SSH + Stunnel Port 80 & 443 (HA Tunnel Style)
# Includes: Auto user expired (1 day), auto IP detection (fallback)

echo "=== 🔧 Setup SSH + Stunnel Port 80 & 443 (Kamuflase ML Axis) ==="

# 1. Update & install tools
apt update -y && apt upgrade -y
apt install -y stunnel4 curl wget net-tools sudo lsof

# 2. Enable stunnel on boot
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4

# 3. Remove old configs
systemctl stop stunnel-freenet80 2>/dev/null
systemctl stop stunnel-hatunnel443 2>/dev/null
rm -f /etc/stunnel/freenet80.conf /etc/stunnel/hatunnel443.conf
rm -f /etc/systemd/system/stunnel-freenet80.service /etc/systemd/system/stunnel-hatunnel443.service

# 4. TLS Certificate (kamuflase bug)
mkdir -p /etc/stunnel
rm -f /etc/stunnel/stunnel.pem
openssl req -new -x509 -days 1095 -nodes \
  -out /etc/stunnel/stunnel.pem \
  -keyout /etc/stunnel/stunnel.pem \
  -subj "/C=ID/ST=Jawa/L=Freenet/O=HA-Tunnel/CN=cdn.mobilelegends.com"

# 5. Config port 80
cat > /etc/stunnel/freenet80.conf <<EOF
pid = /var/run/stunnel-freenet80.pid
cert = /etc/stunnel/stunnel.pem
client = no
foreground = yes
debug = 0
setuid = root
setgid = root

[mlaxis]
accept = 0.0.0.0:80
connect = 127.0.0.1:22
EOF

# 6. Config port 443
cat > /etc/stunnel/hatunnel443.conf <<EOF
pid = /var/run/hatunnel443.pid
cert = /etc/stunnel/stunnel.pem
client = no
foreground = yes
debug = 0
setuid = root
setgid = root

[hatunnel443]
accept = 0.0.0.0:443
connect = 127.0.0.1:22
EOF

# 7. Systemd service for 80
cat > /etc/systemd/system/stunnel-freenet80.service <<EOF
[Unit]
Description=Stunnel Freenet Port 80 (Kamuflase)
After=network.target

[Service]
ExecStart=/usr/bin/stunnel /etc/stunnel/freenet80.conf
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 8. Systemd service for 443
cat > /etc/systemd/system/stunnel-hatunnel443.service <<EOF
[Unit]
Description=Stunnel TLS 443 Kamuflase HA Tunnel
After=network.target

[Service]
ExecStart=/usr/bin/stunnel /etc/stunnel/hatunnel443.conf
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 9. Reload systemd & start services
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable stunnel-freenet80
systemctl enable stunnel-hatunnel443
systemctl start stunnel-freenet80
systemctl start stunnel-hatunnel443

# 10. Create 1-day user (auto expire)
USERNAME="kamuflase"
PASSWORD="mlgratis"
id "$USERNAME" &>/dev/null || useradd -e $(date -d +1day +%Y-%m-%d) -m -s /bin/bash "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd

# 11. Remove expired users
EXPIRED_USERS=$(awk -F: '{ if ($8 && $8!="") { if (system("date +%Y-%m-%d") >= $8) print $1 } }' /etc/shadow)
for u in $EXPIRED_USERS; do
  userdel -r "$u" 2>/dev/null
done

# 12. Detect public IP
IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

# 13. Output info
clear
echo "✅ SETUP COMPLETE: SSH + Stunnel 80 & 443 (1-Day User)"
echo "------------------------------------------------------"
echo "🔑 SSH Server : $IP"
echo "🔌 Port SSH   : 22"
echo "🌐 Port 80    : $IP:80 (bug kamuflase)"
echo "🧊 Port 443   : $IP:443 (TLS bug kamuflase)"
echo "👤 Username   : $USERNAME"
echo "🔐 Password   : $PASSWORD"
echo ""
echo "📱 Payload Port 80:"
echo "CONNECT $IP:80 HTTP/1.1[crlf]Host: cdn.mobilelegends.com[crlf]Connection: keep-alive[crlf][crlf]"
echo ""
echo "📱 TLS 443 Settings (SSL Mode):"
echo "SNI  : cdn.mobilelegends.com"
echo "Port : 443"
echo "Mode : SSL/TLS"
echo "------------------------------------------------------"
