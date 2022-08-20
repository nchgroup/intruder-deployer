#/bin/bash

# Check root
if [[ "$(id -u)" -ne 0 ]]; then
    echo "[-] This script must be run as root user"
    exit 1
fi

# Proxy Information
source config.sh

# Proxy https configuration
cat <<EOF > /etc/systemd/system/chisel-tunnel.service
[Unit]
Description=Chisel tunnel
After=network.target

[Service]
ExecStart=/root/go/bin/chisel client --auth $cloudflare_creds_proxy https://$cloudflare_domain$cloudflare_path_proxy R:2222:localhost:22 9999:socks

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable chisel-tunnel.service
systemctl restart chisel-tunnel.service

echo "[!] You need configure cloudflare"
