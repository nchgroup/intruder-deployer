#!/bin/bash

# Check root
if [[ "$(id -u)" -ne 0 ]]; then
    echo "[-] This script must be run as root user"
    exit 1
fi

source config.sh

# Install chisel
mkdir -p $WORKDIR
cd $WORKDIR
git clone https://github.com/udhos/update-golang
cd update-golang && bash update-golang.sh 2>&1 >/dev/null
source /etc/profile.d/golang_path.sh
cd $HOME

go install github.com/jpillora/chisel@latest

apt install nginx -y
rm -rf /var/www/html/*
rm -rf /etc/nginx/sites-enabled/*
rm -rf /etc/nginx/sites-available/*
echo -n "Not found" > /var/www/html/error.html
echo -n "1" > /var/www/html/index.html
cat <<EOF > /etc/nginx/sites-available/$cloudflare_domain
server {
    server_tokens off;
    root /var/www/html/;
    server_name $cloudflare_domain;
    #listen 127.0.0.1:8443 ssl http2;
    listen 80;
    error_page 400 403 404 500 502 503 504 /error.html;
        location = /error.html {
        etag off;
        add_header content-type "text/plain; charset=utf-8" always;
        root  /var/www/html/;
    }
    location $cloudflare_path_proxy {
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Host \$host:\$server_port;
        proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_pass http://127.0.0.1:8000/;
    }
}
EOF

ln -s /etc/nginx/sites-available/$cloudflare_domain /etc/nginx/sites-enabled/$cloudflare_domain
systemctl restart nginx

cat <<EOF > /etc/systemd/system/chisel-tunnel.service
[Unit]
Description=Chisel tunnel
After=network.target

[Service]
ExecStart=/root/go/bin/chisel server --host 127.0.0.1 -p 8000 --auth $cloudflare_creds_proxy --reverse --socks5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable chisel-tunnel.service
systemctl restart chisel-tunnel.service

echo "[+] Done"
echo "[+] Your backend is: https://$cloudflare_domain$cloudflare_path_proxy"
echo "[!] You need configure Cloudflare DNS to point to your server"