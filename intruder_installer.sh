#!/bin/bash

# Check root
if [[ "$(id -u)" -ne 0 ]]; then
    echo "[-] This script must be run as root user"
    exit 1
fi

# VARS
source config.sh
WORKDIR="$HOME/$intruder_dirname"

# Create SSH config
cat <<EOF >> sshd_config
Include /etc/ssh/sshd_config.d/*.conf
Port $intruder_ssh_port
# Port 22
ListenAdress $intruder_ssh_listen
PermitRootLogin yes
MaxAuthTries 6
PubkeyAuthentication no
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
X11Forwarding yes
PrintMotd no
DebianBanner no
AcceptEnv LANG LC_*
Subsystem	sftp	/usr/lib/openssh/sftp-server
EOF

# sshd_config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
cp $PWD/sshd_config /etc/ssh/sshd_config

# Patch config no interactive apt install
sed -i 's/\#\ conf\_force\_conffold\=YES/conf\_force\_conffold\=YES/g' /etc/ucf.conf

# Init
apt update && DEBIAN_FRONTEND=noninteractive apt dist-upgrade -y

# Firewalld
DEBIAN_FRONTEND=noninteractive apt install -y firewalld
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --zone=public --add-port=443/tcp
firewall-cmd --reload
systemctl disable firewalld


# Disable trashes
systemctl disable \
	nfs-config.service \
	rpcbind.service \
	rpc-statd.service \
	nfs-server.service


# Install essential tools
DEBIAN_FRONTEND=noninteractive apt install -y \
	nmap \
	arp-scan \
	netdiscover \
	autossh \
	nbtscan \
	prips \
	python3-pip \
	python3-dev \
	tcpdump \
	macchanger \
	traceroute \
	tshark \
	wipe \
	libpcap-dev \
	hping3 \
	sslh \
	ettercap-text-only \
	proxychains4

pip3 install scapy

# Git clone
git clone https://github.com/lgandx/Responder $WORKDIR/Responder


# Change hostname
hostnamectl set-hostname localhost
sed -i 's/'$HOSTNAME'/localhost/g' /etc/hosts

# Install crackmapexec
DEBIAN_FRONTEND=noninteractive apt install -y libffi-dev
pip3 install cffi
mkdir $WORKDIR/cme; cd $WORKDIR/cme
wget "https://github.com/Porchetta-Industries/CrackMapExec/releases/download/v5.3.0/cme-ubuntu-latest-3.10.zip"
unzip cme-ubuntu-latest-3.10.zip
chmod +x cme

# Disable NTP Sync
#sudo timedatectl set-ntp no

# Install Golang
cd $WORKDIR
git clone https://github.com/udhos/update-golang
cd update-golang && bash update-golang.sh 2>&1 >/dev/null
source /etc/profile.d/golang_path.sh

# Install Golang tools
go install github.com/projectdiscovery/simplehttpserver/cmd/simplehttpserver@latest
go install github.com/jpillora/chisel@latest

# Install bettercap
DEBIAN_FRONTEND=noninteractive apt install -y \
	build-essential \
	libpcap-dev \
	libusb-1.0-0-dev \
	libnetfilter-queue-dev
go install github.com/bettercap/bettercap@latest

# install DoH
DEBIAN_FRONTEND=noninteractive apt install dnscrypt-proxy
cat <<EOF > /etc/NetworkManager/conf.d/00-dns.conf
[main]
dns=none
EOF
systemctl restart NetworkManager.service
cat <<EOF > /etc/resolv.conf
nameserver ::ffff:7f00:201
nameserver 127.0.2.1
options edns0 single-request-reopen
EOF
systemctl start dnscrypt-proxy.service
systemctl enable dnscrypt-proxy.service
systemctl restart NetworkManager.service

# ssh key gen
echo -e "\n\n"
echo "[*] generating ssh key"
mkdir $HOME/.ssh
ssh-keygen -f $HOME/.ssh/id_rsa -t rsa -N ''
echo ">>> Please copy this pub key in your vps <<<"
echo -e "\n\n"
cat $HOME/.ssh/id_rsa.pub
echo -e "\n\n"

echo -e "\n\n"
echo "[!] Don't forget to save your user/password for local ssh and your keys for tunnel"

# Install fscrypt
DEBIAN_FRONTEND=noninteractive apt-get -y install fscrypt
fscrypt setup
tune2fs -O encrypt "/dev/mmcblk0p1"
mkdir $PWD/private
fscrypt encrypt $PWD/private --source=custom_passphrase --name=pi
# umount
echo
echo "> umounting: $ fscrypt lock $PWD/private"
# mount
echo "> mounting: $ fscrypt unlock $PWD/private"