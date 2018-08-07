#!/bin/bash

IFS=$'\n\t'

exec 1>/tmp/cloudware-gateway-setup-output 2>&1

#################
# PREREQUISITES #
#################
yum install -y syslinux git httpd

########
# VARS #
########

# Software
everyware_CLOUDWARE_VERSION="${everyware_CLOUDWARE_VERSION:-dev/everyware}"
everyware_METALWARE_VERSION="${everyware_METALWARE_VERSION:-2018.3.0-rc2}"


# VPN Specific
# everyware_VPN_CLUSTERS="${everyware_VPN_CLUSTERS:-cluster1 cluster2 cluster3 cluster4 clusterX}" # Space separated list of clusters


# Metalware Specific
everyware_METALWARE_REPO="${everyware_METALWARE_REPO:-dev/everyware}"

# IPA Specific
everyware_IPA_PASSWORD="${everyware_IPA_PASSWORD:-REPLACE_ME}"
everyware_IPA_HOST="${everyware_IPA_HOST:-$(hostname -f)}"
everyware_IPA_HOSTIP="${everyware_IPA_HOSTIP:-$(gethostip -d $(hostname))}"
everyware_IPA_REALM="${everyware_IPA_REALM:-$(hostname -d |sed 's/^[^.]*.//g' |tr '[a-z]' '[A-Z]')}"
everyware_IPA_DOMAIN="${everyware_IPA_DOMAIN:-$(hostname -d)}"
everyware_IPA_DNS="${everyware_IPA_DNS:-$(grep nameserver -m 1 /etc/resolv.conf  |sed 's/nameserver //g')}"
everyware_IPA_REVERSE="${everyware_IPA_REVERSE:-$(gethostip -d $(hostname) |awk -F. '{print $2"."$1}')}"

if [ $everyware_IPA_PASSWORD == "REPLACE_ME" ] ; then
    echo "The IPA password needs to be provided as a CLI argument"
    echo "To do this when curling the script:"
    echo "  curl http://path/to/domain0-gateway.sh |everyware_IPA_PASSWORD=MySecurePassword /bin/bash"
    exit 1
fi

echo "

#####################
# VPN Configuration #
#####################

"
yum -y install epel-release
yum -y install openvpn easy-rsa
cp -pav /usr/share/easy-rsa/3.0.3 /etc/openvpn/easyrsa
cd /etc/openvpn/easyrsa

cat<< 'EOF' > /etc/openvpn/easyrsa/vars
if [ -z "$EASYRSA_CALLER" ]; then
    echo "You appear to be sourcing an Easy-RSA 'vars' file." >&2
    echo "This is no longer necessary and is disallowed. See the section called" >&2
    echo "'How to use this file' near the top comments for more details." >&2
    return 1
fi
set_var EASYRSA        "$PWD"
set_var EASYRSA_OPENSSL        "openssl"
set_var EASYRSA_PKI            "$EASYRSA/pki"
set_var EASYRSA_DN     "org"
set_var EASYRSA_REQ_COUNTRY    "UK"
set_var EASYRSA_REQ_PROVINCE   "Oxfordshire"
set_var EASYRSA_REQ_CITY       "Oxford"
set_var EASYRSA_REQ_ORG        "Alces Flight Ltd"
set_var EASYRSA_REQ_EMAIL      "ssl@alces-flight.com"
set_var EASYRSA_REQ_OU         "Infrastructure"
set_var EASYRSA_KEY_SIZE       2048
set_var EASYRSA_ALGO           rsa
set_var EASYRSA_CA_EXPIRE      3650
set_var EASYRSA_CERT_EXPIRE    3650
set_var EASYRSA_CRL_DAYS       180
set_var EASYRSA_TEMP_FILE      "$EASYRSA_PKI/extensions.temp"
set_var EASYRSA_BATCH 		"true"
EOF

./easyrsa init-pki
./easyrsa --req-cn=cluster0 build-ca nopass

./easyrsa --req-cn=cluster0 gen-req cluster0 nopass
./easyrsa sign-req server cluster0

./easyrsa --req-cn=clusterX gen-req clusterX nopass
./easyrsa sign-req client clusterX

./easyrsa --req-cn=cluster1 gen-req cluster1 nopass
./easyrsa sign-req client cluster1

./easyrsa --req-cn=cluster2 gen-req cluster2 nopass
./easyrsa sign-req client cluster2

./easyrsa --req-cn=cluster3 gen-req cluster3 nopass
./easyrsa sign-req client cluster3

./easyrsa --req-cn=cluster4 gen-req cluster4 nopass
./easyrsa sign-req client cluster4

./easyrsa gen-dh
./easyrsa gen-crl
openvpn --genkey --secret ta.key

cat << EOF > /etc/openvpn/flightconnector.conf
mode server
tls-server
port 2005
proto tcp-server
dev tun0
ca /etc/openvpn/easyrsa/pki/ca.crt
cert /etc/openvpn/easyrsa/pki/issued/cluster0.crt
key /etc/openvpn/easyrsa/pki/private/cluster0.key
dh /etc/openvpn/easyrsa/pki/dh.pem
crl-verify /etc/openvpn/easyrsa/pki/crl.pem
client-config-dir ccd-clusters
ccd-exclusive
client-to-client
ifconfig 10.78.110.1 255.255.255.0
topology subnet
route 10.10.0.0 255.255.0.0 10.78.110.2
route 10.100.1.0 255.255.255.0 10.78.110.11
route 10.100.2.0 255.255.255.0 10.78.110.12
route 10.100.3.0 255.255.255.0 10.78.110.13
route 10.100.4.0 255.255.255.0 10.78.110.14
keepalive 10 120
comp-lzo adaptive
tls-auth /etc/openvpn/easyrsa/ta.key 0
cipher AES-256-CBC
auth SHA512
tls-version-min 1.2
tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384
persist-key
persist-tun
status openvpn-status.log
log         /var/log/openvpn.log
log-append  /var/log/openvpn.log
verb 3
EOF

mkdir /etc/openvpn/ccd-clusters
cat << EOF > /etc/openvpn/ccd-clusters/clusterX
ifconfig-push 10.78.110.2 255.255.255.0
push "route 10.78.100.0 255.255.255.0 10.78.110.1"
push "route 10.100.1.0 255.255.255.0 10.78.110.11"
push "route 10.100.2.0 255.255.255.0 10.78.110.12"
push "route 10.100.3.0 255.255.255.0 10.78.110.13"
push "route 10.100.4.0 255.255.255.0 10.78.110.14"
iroute 10.10.0.0 255.255.0.0
EOF

cat << EOF > /etc/openvpn/ccd-clusters/cluster1
ifconfig-push 10.78.110.11 255.255.255.0
push "route 10.78.100.0 255.255.255.0 10.78.110.1"
push "route 10.10.0.0 255.255.0.0 10.78.110.2"
push "route 10.100.2.0 255.255.255.0 10.78.110.12"
push "route 10.100.3.0 255.255.255.0 10.78.110.13"
push "route 10.100.4.0 255.255.255.0 10.78.110.14"
iroute 10.100.1.0 255.255.255.0
EOF

cat << EOF > /etc/openvpn/ccd-clusters/cluster2
ifconfig-push 10.78.110.12 255.255.255.0
push "route 10.78.100.0 255.255.255.0 10.78.110.1"
push "route 10.10.0.0 255.255.0.0 10.78.110.2"
push "route 10.100.1.0 255.255.255.0 10.78.110.11"
push "route 10.100.3.0 255.255.255.0 10.78.110.13"
push "route 10.100.4.0 255.255.255.0 10.78.110.14"
iroute 10.100.2.0 255.255.255.0
EOF

cat << EOF > /etc/openvpn/ccd-clusters/cluster3
ifconfig-push 10.78.110.13 255.255.255.0
push "route 10.78.100.0 255.255.255.0 10.78.110.1"
push "route 10.10.0.0 255.255.0.0 10.78.110.2"
push "route 10.100.1.0 255.255.255.0 10.78.110.11"
push "route 10.100.2.0 255.255.255.0 10.78.110.12"
push "route 10.100.4.0 255.255.255.0 10.78.110.13"
iroute 10.100.3.0 255.255.255.0
EOF

cat << EOF > /etc/openvpn/ccd-clusters/cluster4
ifconfig-push 10.78.110.14 255.255.255.0
push "route 10.78.100.0 255.255.255.0 10.78.110.1"
push "route 10.10.0.0 255.255.0.0 10.78.110.2"
push "route 10.100.1.0 255.255.255.0 10.78.110.11"
push "route 10.100.2.0 255.255.255.0 10.78.110.12"
push "route 10.100.3.0 255.255.255.0 10.78.110.13"
iroute 10.100.4.0 255.255.255.0
EOF


cat << '_EOF_' >> /etc/openvpn/buildinstaller.sh
CLUSTER=$1
IP=`curl --silent http://ipecho.net/plain`
CA=`cat /etc/openvpn/easyrsa/pki/ca.crt`
CRT=`cat /etc/openvpn/easyrsa/pki/issued/$CLUSTER.crt`
KEY=`cat /etc/openvpn/easyrsa/pki/private/$CLUSTER.key`
TA=`cat /etc/openvpn/easyrsa/ta.key`
cat << EOF > /root/install_$CLUSTER.run
yum install -y epel-release
yum install -y openvpn
cat << EOD > /etc/openvpn/flightconnector.conf
client
dev tun
proto tcp
remote $IP 2005
remote-cert-tls server
resolv-retry infinite
nobind
persist-key
persist-tun
<ca>
$CA
</ca>
<cert>
$CRT
</cert>
<key>
$KEY
</key>
comp-lzo adaptive
verb 0
cipher AES-256-CBC
auth SHA512
tls-version-min 1.2
tls-client
tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384
key-direction 1
<tls-auth>
$TA
</tls-auth>
topology subnet
EOD
systemctl enable openvpn@flightconnector
systemctl start openvpn@flightconnector
systemctl disable iptables
systemctl enable firewalld
systemctl stop iptables
systemctl start firewalld
systemctl disable cloud-init
systemctl disable cloud-init-local
systemctl disable cloud-config
systemctl disable cloud-final

firewall-cmd --new-zone $CLUSTER --permanent
firewall-cmd --add-interface tun0 --zone $CLUSTER --permanent
firewall-cmd --remove-interface eth0 --zone public
firewall-cmd --remove-interface eth0 --zone public --permanent
firewall-cmd --add-interface eth0 --zone external --permanent
firewall-cmd --add-interface eth0 --zone external
firewall-cmd --add-port 2005/tcp --zone external --permanent

firewall-cmd --set-target=ACCEPT --zone $CLUSTER --permanent

sed '/^ZONE=/{h;s/=.*/=external/};\${x;/^$/{s//ZONE=external/;H};x}' /etc/sysconfig/network-scripts/ifcfg-eth0 -i

echo "Please reboot"
EOF
_EOF_

bash /etc/openvpn/buildinstaller.sh clusterX
bash /etc/openvpn/buildinstaller.sh cluster1
bash /etc/openvpn/buildinstaller.sh cluster2
bash /etc/openvpn/buildinstaller.sh cluster3
bash /etc/openvpn/buildinstaller.sh cluster4


systemctl enable openvpn@flightconnector


systemctl disable iptables
systemctl enable firewalld
systemctl stop iptables
systemctl start firewalld
systemctl disable cloud-init
systemctl disable cloud-init-local
systemctl disable cloud-config
systemctl disable cloud-final

firewall-cmd --new-zone cluster0 --permanent
firewall-cmd --add-interface tun0 --zone cluster0 --permanent
firewall-cmd --remove-interface eth0 --zone public
firewall-cmd --remove-interface eth0 --zone public --permanent
firewall-cmd --add-interface eth0 --zone external --permanent
firewall-cmd --add-interface eth0 --zone external
firewall-cmd --add-port 2005/tcp --zone external --permanent

firewall-cmd --set-target=ACCEPT --zone cluster0 --permanent

sed '/^ZONE=/{h;s/=.*/=external/};${x;/^$/{s//ZONE=external/;H};x}' /etc/sysconfig/network-scripts/ifcfg-eth0 -i


echo "

###################
# VPN HTTP SERVER #
###################

"
firewall-cmd --add-port 80/tcp --zone external --permanent
firewall-cmd --reload
mkdir /var/www/html/vpn
mv /root/install_cluster* /var/www/html/vpn

cat << EOF > /etc/httpd/conf.d/vpn.conf
<Directory /var/www/html/vpn/>
    Options Indexes MultiViews FollowSymlinks
    AllowOverride None
    Require all granted
    Order Allow,Deny
    Allow from all
    Allow from 127.0.0.1/8
</Directory>
Alias /vpn /var/www/html/vpn
EOF




echo "

#############
# CLOUDWARE #
#############

"
curl -sL https://git.io/vbsTg | alces_OS=el7 alces_SOURCE_BRANCH=$everyware_CLOUDWARE_VERSION /bin/bash


echo "

#############
# METALWARE #
#############

"
curl -sL http://git.io/metalware-installer |alces_OS=el7 alces_SOURCE_BRANCH=$everyware_METALWARE_VERSION /bin/bash
metal repo use https://github.com/alces-software/metalware-repo-base.git
cd /var/lib/metalware/repo/
git checkout $everyware_METALWARE_REPO
mv plugins/* ../plugins/

# Workaround for build errors
mkdir -p /var/lib/tftpboot/pxelinux.cfg



echo "

##############
# IPA SERVER #
##############

"

# Install Userware
git clone https://github.com/alces-software/userware /tmp/userware
rsync -auv /tmp/userware/{directory,share} /opt/

cd /opt/directory/cli
make setup

mkdir /opt/directory/etc
echo "cw_ACCESS_fqdn=$(hostname -f)" > /opt/directory/etc/access.rc
echo "IPAPASSWORD=$everyware_IPA_PASSWORD" > /opt/directory/etc/config

mkdir -p /var/www/html/secure

# Branding
mkdir -p /opt/flight/bin
cd /opt/flight/bin
curl https://s3-eu-west-1.amazonaws.com/flightconnector/directory/resources/banner > banner
chmod 755 banner

cd /opt/directory/cli/bin
curl https://s3-eu-west-1.amazonaws.com/flightconnector/directory/resources/sandbox-starter > sandbox-starter

# IPA Admin User Config
su - ipaadmin -c "ssh-keygen -f /home/ipaadmin/.ssh/id_rsa -N ''"
cat << EOF > /home/ipaadmin/.ssh/authorized_keys
command="/opt/directory/cli/bin/sandbox-starter",no-port-forwarding,no-x11-forwarding,no-agent-forwarding $(cat /home/ipaadmin/.ssh/id_rsa.pub)
EOF
chown ipaadmin:ipaadmin /home/ipaadmin/.ssh/authorized_keys
chmod 600 /home/ipaadmin/.ssh/authorized_keys
passwd -l ipaadmin

echo 'AcceptEnv FC_*' >> /etc/ssh/sshd_config

# IPA Server Install
yum -y install ipa-server bind bind-dyndb-ldap ipa-server-dns

systemctl restart dbus # fix for certmonger error https://bugzilla.redhat.com/show_bug.cgi?id=1504688

ipa-server-install -a $everyware_IPA_PASSWORD --hostname $everyware_IPA_HOST --ip-address=$everyware_IPA_HOSTIP -r "$everyware_IPA_REALM" -p $everyware_IPA_PASSWORD -n "$everyware_IPA_DOMAIN" --no-ntp --setup-dns --forwarder="$everyware_IPA_DNS" --reverse-zone="$everyware_IPA_REVERSE.in-addr.arpa." --ssh-trust-dns --unattended


echo "Please reboot"
