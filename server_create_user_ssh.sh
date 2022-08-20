#!/bin/bash

source config.sh

if [ "$intruder_rsa_pub_key" == "" ]; then
    echo "[-] You need to configure intruder_rsa_pub_key in config.sh"
    exit 1
fi

if [[ "$(id -u)" == '0' ]]; then
    sed -i -E 's/\#?Port\ 22/Port\ '$vps_remote_ssh_port'/g' /etc/ssh/sshd_config
    systemctl restart ssh
    useradd --base-dir /home --create-home --shell /bin/false $vps_remote_user
    mkdir -p /home/$vps_remote_user/.ssh
    echo "$intruder_rsa_pub_key" > /home/$vps_remote_user/.ssh/authorized_keys
    chown -R $vps_remote_user:$vps_remote_user /home/$vps_remote_user
    chmod -R 700 /home/$vps_remote_user/.ssh
    chmod 400 /home/$vps_remote_user/.ssh/authorized_keys
    printf '[+] Done...\n'
fi