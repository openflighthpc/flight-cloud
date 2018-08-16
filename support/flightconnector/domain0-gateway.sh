#!/bin/bash

IFS=$'\n\t'

exec 1>/tmp/cloudware-gateway-setup-output 2>&1

########
# VARS #
########

# Install syslinux for setting up variables
yum install -y syslinux

# General
everyware_CLOUDWARE_DOMAIN_NAME="${everyware_CLUSTER_NAME:-$(hostname -d |sed 's/^[^.]*.//;s/\..*//g')}" # e.g. 'dom0.mycluster.alces.network' becomes 'mycluster'
everyware_CLOUDWARE_DOMAIN_NETWORK="${everyware_CLOUDWARE_DOMAIN_NETWORK:-10.78.0.0}"
everyware_PRIMARY_INTERFACE="${everyware_PRIMARY_INTERFACE:-eth0}"
everyware_CLUSTER1_NAME="${everyware_CLUSTER1_NAME:-cluster1}"
everyware_CLUSTER1_NETWORK="${everyware_CLUSTER1_NETWORK:-10.100.1.0}"
everyware_CLUSTER2_NAME="${everyware_CLUSTER2_NAME:-cluster2}"
everyware_CLUSTER2_NETWORK="${everyware_CLUSTER2_NETWORK:-10.100.2.0}"
everyware_CLUSTER3_NAME="${everyware_CLUSTER3_NAME:-cluster3}"
everyware_CLUSTER3_NETWORK="${everyware_CLUSTER3_NETWORK:-10.100.3.0}"
everyware_CLUSTER4_NAME="${everyware_CLUSTER4_NAME:-cluster4}"
everyware_CLUSTER4_NETWORK="${everyware_CLUSTER4_NETWORK:-10.100.4.0}"

# Software
everyware_CLOUDWARE_VERSION="${everyware_CLOUDWARE_VERSION:-dev/everyware}"
everyware_METALWARE_VERSION="${everyware_METALWARE_VERSION:-2018.3.0}"

# Metalware Specific
everyware_METALWARE_REPO="${everyware_METALWARE_REPO:-dev/everyware}"

# IPA Specific
everyware_IPA_SECUREPASSWORD="${everyware_IPA_SECUREPASSWORD:-REPLACE_ME}"
everyware_IPA_INSECUREPASSWORD="${everyware_IPA_INSECUREPASSWORD:-REPLACE_ME}"
everyware_IPA_HOST="${everyware_IPA_HOST:-$(hostname -f)}"
everyware_IPA_HOSTIP="${everyware_IPA_HOSTIP:-$(gethostip -d $(hostname))}"
everyware_IPA_REALM="${everyware_IPA_REALM:-$(hostname -d |sed 's/^[^.]*.//g' |tr '[a-z]' '[A-Z]')}"
everyware_IPA_REALM_DOWNCASE="${everyware_IPA_REALM_DOWNCASE:-$(hostname -d |sed 's/^[^.]*.//g')}"
everyware_IPA_DOMAIN="${everyware_IPA_DOMAIN:-$(hostname -d)}"
everyware_IPA_DNS="${everyware_IPA_DNS:-$(grep nameserver -m 1 /etc/resolv.conf  |sed 's/nameserver //g')}"
everyware_IPA_REVERSE="${everyware_IPA_REVERSE:-$(gethostip -d $(hostname) |awk -F. '{print $2"."$1}')}"

if [[ $everyware_IPA_SECUREPASSWORD == "REPLACE_ME" || $everyware_IPA_INSECUREPASSWORD == "REPLACE_ME" ]] ; then
    echo "The IPA passwords needs to be provided as a CLI argument"
    echo "To do this when curling the script:"
    echo "  curl http://path/to/domain0-gateway.sh |everyware_IPA_SECUREPASSWORD=MySecurePassword everyware_IPA_INSECUREPASSWORD=MyInsecurePassword /bin/bash"
    exit 1
fi

echo "

#################
# PREREQUISITES #
#################

"
yum install -y git httpd epel-release ipa-server bind bind-dyndb-ldap ipa-server-dns firefox
yum install -y openvpn easy-rsa
yum update -y

firewall-cmd --add-service ldap --add-service ldaps --add-service kerberos\
    --add-service kpasswd --add-service http --add-service https\
    --add-service dns --add-service mountd --add-service nfs\
    --add-service ntp --add-service syslog\
    --zone external --permanent

echo "

#####################
# VPN Configuration #
#####################

"
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

./easyrsa --req-cn=$everyware_CLUSTER1_NAME gen-req $everyware_CLUSTER1_NAME nopass
./easyrsa sign-req client $everyware_CLUSTER1_NAME

./easyrsa --req-cn=$everyware_CLUSTER2_NAME gen-req $everyware_CLUSTER2_NAME nopass
./easyrsa sign-req client $everyware_CLUSTER2_NAME

./easyrsa --req-cn=$everyware_CLUSTER3_NAME gen-req $everyware_CLUSTER3_NAME nopass
./easyrsa sign-req client $everyware_CLUSTER3_NAME

./easyrsa --req-cn=$everyware_CLUSTER4_NAME gen-req $everyware_CLUSTER4_NAME nopass
./easyrsa sign-req client $everyware_CLUSTER4_NAME

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
route $everyware_CLUSTER1_NETWORK 255.255.255.0 10.78.110.11
route $everyware_CLUSTER2_NETWORK 255.255.255.0 10.78.110.12
route $everyware_CLUSTER3_NETWORK 255.255.255.0 10.78.110.13
route $everyware_CLUSTER4_NETWORK 255.255.255.0 10.78.110.14
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
push "route $everyware_CLUSTER1_NETWORK 255.255.255.0 10.78.110.11"
push "route $everyware_CLUSTER2_NETWORK 255.255.255.0 10.78.110.12"
push "route $everyware_CLUSTER3_NETWORK 255.255.255.0 10.78.110.13"
push "route $everyware_CLUSTER4_NETWORK 255.255.255.0 10.78.110.14"
iroute 10.10.0.0 255.255.0.0
EOF

cat << EOF > /etc/openvpn/ccd-clusters/$everyware_CLUSTER1_NAME
ifconfig-push 10.78.110.11 255.255.255.0
push "route 10.78.100.0 255.255.255.0 10.78.110.1"
push "route 10.10.0.0 255.255.0.0 10.78.110.2"
push "route $everyware_CLUSTER2_NETWORK 255.255.255.0 10.78.110.12"
push "route $everyware_CLUSTER3_NETWORK 255.255.255.0 10.78.110.13"
push "route $everyware_CLUSTER4_NETWORK 255.255.255.0 10.78.110.14"
iroute $everyware_CLUSTER1_NETWORK 255.255.255.0
EOF

cat << EOF > /etc/openvpn/ccd-clusters/$everyware_CLUSTER2_NAME
ifconfig-push 10.78.110.12 255.255.255.0
push "route 10.78.100.0 255.255.255.0 10.78.110.1"
push "route 10.10.0.0 255.255.0.0 10.78.110.2"
push "route $everyware_CLUSTER1_NETWORK 255.255.255.0 10.78.110.11"
push "route $everyware_CLUSTER3_NETWORK 255.255.255.0 10.78.110.13"
push "route $everyware_CLUSTER4_NETWORK 255.255.255.0 10.78.110.14"
iroute $everyware_CLUSTER2_NETWORK 255.255.255.0
EOF

cat << EOF > /etc/openvpn/ccd-clusters/$everyware_CLUSTER3_NAME
ifconfig-push 10.78.110.13 255.255.255.0
push "route 10.78.100.0 255.255.255.0 10.78.110.1"
push "route 10.10.0.0 255.255.0.0 10.78.110.2"
push "route $everyware_CLUSTER1_NETWORK 255.255.255.0 10.78.110.11"
push "route $everyware_CLUSTER2_NETWORK 255.255.255.0 10.78.110.12"
push "route $everyware_CLUSTER4_NETWORK 255.255.255.0 10.78.110.13"
iroute $everyware_CLUSTER3_NETWORK 255.255.255.0
EOF

cat << EOF > /etc/openvpn/ccd-clusters/$everyware_CLUSTER4_NAME
ifconfig-push 10.78.110.14 255.255.255.0
push "route 10.78.100.0 255.255.255.0 10.78.110.1"
push "route 10.10.0.0 255.255.0.0 10.78.110.2"
push "route $everyware_CLUSTER1_NETWORK 255.255.255.0 10.78.110.11"
push "route $everyware_CLUSTER2_NETWORK 255.255.255.0 10.78.110.12"
push "route $everyware_CLUSTER3_NETWORK 255.255.255.0 10.78.110.13"
iroute $everyware_CLUSTER4_NETWORK 255.255.255.0
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
bash /etc/openvpn/buildinstaller.sh $everyware_CLUSTER1_NAME
bash /etc/openvpn/buildinstaller.sh $everyware_CLUSTER2_NAME
bash /etc/openvpn/buildinstaller.sh $everyware_CLUSTER3_NAME
bash /etc/openvpn/buildinstaller.sh $everyware_CLUSTER4_NAME


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
firewall-cmd --remove-interface $everyware_PRIMARY_INTERFACE --zone public
firewall-cmd --remove-interface $everyware_PRIMARY_INTERFACE --zone public --permanent
firewall-cmd --add-interface $everyware_PRIMARY_INTERFACE --zone external --permanent
firewall-cmd --add-interface $everyware_PRIMARY_INTERFACE --zone external
firewall-cmd --add-port 2005/tcp --zone external --permanent

firewall-cmd --set-target=ACCEPT --zone cluster0 --permanent

sed '/^ZONE=/{h;s/=.*/=external/};${x;/^$/{s//ZONE=external/;H};x}' /etc/sysconfig/network-scripts/ifcfg-$everyware_PRIMARY_INTERFACE -i


echo "

###################
# VPN HTTP SERVER #
###################

"
firewall-cmd --add-port 80/tcp --zone external --permanent
firewall-cmd --reload
mkdir /var/www/html/vpn
mv /root/install_* /var/www/html/vpn

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
source /etc/profile.d/alces-metalware.sh
metal repo use https://github.com/alces-software/metalware-repo-base.git
cd /var/lib/metalware/repo/
git checkout $everyware_METALWARE_REPO
mv plugins/* ../plugins/

# Update metalware config
#
#  Ideally this would be done with configure --answers but due to this requiring questions
#  to be in configure.yaml it does not achieve the goal of minimising the questions
#  being asked.
#
#     metal configure domain --answers "{ \"cluster_name\": \"$everyware_CLOUDWARE_DOMAIN_NAME/\" }"
#
#  The `--answers` are currently being used alongside stripping out some questions to reach a
#  comfortable medium where configure will not usually need to be run and if it is then most
#  of the questions are already answered

## Domain config
metal configure domain --answers "{ \"metalware_internal--plugin_enabled--firstrun\": true, \
    \"metalware_internal--plugin_enabled--firstrun\": true, \
    \"metalware_internal--plugin_enabled--flightdirect\": false, \
    \"metalware_internal--plugin_enabled--ganglia\": true, \
    \"ganglia_serverip\": \"$everyware_IPA_HOSTIP\", \
    \"metalware_internal--plugin_enabled--infiniband\": false, \
    \"metalware_internal--plugin_enabled--ipa\": true, \
    \"ipa_serverip\": \"$everyware_IPA_HOSTIP\", \
    \"ipa_servername\": \"$everyware_IPA_HOST\", \
    \"ipa_insecurepassword\": \"$everyware_IPA_INSECUREPASSWORD\", \
    \"ipa_userdir\": \"/users/\", \
    \"metalware_internal--plugin_enabled--lustre\": false, \
    \"metalware_internal--plugin_enabled--nfs\": true, \
    \"nfs_isclient\": true, \
    \"metalware_internal--plugin_enabled--nvidia\": false, \
    \"metalware_internal--plugin_enabled--rootrun\": false, \
    \"metalware_internal--plugin_enabled--slurm\": false, \
    \"metalware_internal--plugin_enabled--yumrepo\": false }"

cat << EOF > /var/lib/metalware/repo/config/domain.yaml
cluster: $everyware_CLOUDWARE_DOMAIN_NAME
# GENERATE with openssl passwd -1 \$PASSWD.
# XXX Change this so admin enters plain text root password, and we generate
# encrypted password here?
encrypted_root_password: '<%= answer.root_password %>'
profile: MASTER
ssh_key: '<%= answer.root_ssh_key %>'
build_method: basic

domain: $everyware_IPA_REALM_DOWNCASE
cloudware_domain: $everyware_CLOUDWARE_DOMAIN_NETWORK
search_domains: "<% config.networks.each do |network, details| -%><% next if network.to_s == 'ext' %><%= details.domain %><%= if network.to_s == 'bmc' then '.mgt' else '' end %>.<%= config.domain %> <% end -%><%= config.domain %>"
dns_type: "<%= answer.dns_type %>"
externaldns: $everyware_IPA_DNS
internaldns: $everyware_IPA_HOSTIP

# Properties for specific config.networks.
networks:
  pri:
    defined: true
    interface: eth0
    hostname: "<%= config.networks.pri.short_hostname %>.<%= config.domain %>"
    domain: pri
    short_hostname: "<%= node.name.sub(node.group.name + '-', '') %>.<%= config.networks.pri.domain %>"
    ip: <%= answer.pri_network_ip_node || answer.pri_network_ip || "10.100.#{node.group.index}.#{node.index + 19}"%>
    netmask: 255.255.255.0
    network: <%= answer.pri_network_network || "10.100.#{node.group.index}.0" %>
    gateway: <%= answer.pri_network_gateway || "10.100.#{node.group.index}.10" %>
    primary: true
    named_fwd_zone: "<%= config.networks.pri.domain %>.<%= config.domain %>"
    named_rev_zone: <% split_net = config.networks.pri.network.split(/\./) -%><%= split_net[1] %>.<%= split_net[0] %>
    firewallpolicy: trusted

files:
  platform:
    - /opt/alces/install/scripts/aws.sh
  main:
    - main.sh
  setup:
    - local-script.sh
  core:
    - core/base.sh
    - core/chrony.sh
    - core/configs/chrony.conf
    - core/firstrun_scripts/chronyfix.bash
    - core/syslog.sh
    - core/configs/metalware.conf
    - core/configs/rsyslog-remote
    - core/firstrun_scripts/firewall_rsyslog.bash
    - core/postfix.sh
    - core/network-base.sh
    - core/network-join.sh
    - core/networking.sh
    - core/configs/authorized_keys
    - core/firstrun_scripts/firewall_main.bash
  scripts:
    - local-script.sh

ntp:
  is_server: false
  server: gateway.dom0.<%= config.domain %>

rsyslog:
  is_server: false
  server: gateway

firewall:
  enabled: true
  internal:
    services: 'ssh http dhcp dns https mountd nfs ntp rpc-bind smtp syslog tftp tftp-client'
  external:
    services: 'ssh'
  management:
    services: 'ssh snmp'

postfix:
  relayhost: gateway.dom0.<%= config.domain %>
EOF

metal sync

## Local config
#metal configure local --answers "{ \"ganglia_isserver\": true, \"nfs_isserver\": true }"

## Workaround until local --answers is merged into official release
mkdir -p /var/lib/metalware/staging/var/lib/metalware/rendered/system
echo 'local    orphan' > /var/lib/metalware/staging/var/lib/metalware/rendered/system/genders
cat << EOF > /var/lib/metalware/answers/nodes/local.yaml
ganglia_isserver: true
nfs_isserver: true
EOF

cat << EOF > /var/lib/metalware/repo/config/local.yaml
networks:
  pri:
    defined: true
    ip: $everyware_IPA_HOSTIP
    netmask: 255.255.0.0
    network: $everyware_CLOUDWARE_DOMAIN_NETWORK
    short_hostname: $everyware_IPA_HOST
    interface: $everyware_PRIMARY_INTERFACE
build_method: self
files:
  setup:
    - local/dns.sh
    - local/xinetd.sh
    - local/http.sh
  main:
    - local/main.sh
  core:
    - core/base.sh
    - core/chrony.sh
    - core/configs/chrony.conf
    - core/firstrun_scripts/chronyfix.bash
    - core/syslog.sh
    - core/configs/metalware.conf
    - core/configs/rsyslog-remote
    - core/firstrun_scripts/firewall_rsyslog.bash
    - core/postfix.sh
    - core/network-base.sh
    - core/network-join.sh
    - core/networking.sh
    - core/configs/authorized_keys
    - local/extra.sh
    - core/configs/dhcpd.conf
    - core/configs/pxelinux_default
    - core/configs/named.conf
    - core/configs/http/deployment.conf
    - core/configs/http/installer.conf
    - core/configs/kscomplete.php
    - core/firstrun_scripts/firewall_main.bash
build:
  pxeboot_path: /var/lib/tftpboot/boot
ntp:
  is_server: true
rsyslog:
  is_server: true
EOF

metal sync

## Cluster configs
metal configure group $everyware_CLUSTER1_NAME --answers "{ \"genders_host_range\": \"$everyware_CLUSTER1_NAME-node[01-10],$everyware_CLUSTER1_NAME-login1\", \"genders_all_group\": true }"
metal configure group $everyware_CLUSTER2_NAME --answers "{ \"genders_host_range\": \"$everyware_CLUSTER2_NAME-node[01-10],$everyware_CLUSTER2_NAME-login1\", \"genders_all_group\": true }"
metal configure group $everyware_CLUSTER3_NAME --answers "{ \"genders_host_range\": \"$everyware_CLUSTER3_NAME-node[01-10],$everyware_CLUSTER3_NAME-login1\", \"genders_all_group\": true }"
metal configure group $everyware_CLUSTER4_NAME --answers "{ \"genders_host_range\": \"$everyware_CLUSTER4_NAME-node[01-10],$everyware_CLUSTER4_NAME-login1\", \"genders_all_group\": true }"

metal sync

## Cluster login node configs
metal configure node $everyware_CLUSTER1_NAME-login1 --answers "{ \"pri_network_ip_node\": \"10.100.<%= node.group.index %>.10\", \"pri_network_gateway\": \"10.100.<%= node.group.index %>.1\" }"
metal configure node $everyware_CLUSTER2_NAME-login1 --answers "{ \"pri_network_ip_node\": \"10.100.<%= node.group.index %>.10\", \"pri_network_gateway\": \"10.100.<%= node.group.index %>.1\" }"
metal configure node $everyware_CLUSTER3_NAME-login1 --answers "{ \"pri_network_ip_node\": \"10.100.<%= node.group.index %>.10\", \"pri_network_gateway\": \"10.100.<%= node.group.index %>.1\" }"
metal configure node $everyware_CLUSTER4_NAME-login1 --answers "{ \"pri_network_ip_node\": \"10.100.<%= node.group.index %>.10\", \"pri_network_gateway\": \"10.100.<%= node.group.index %>.1\" }"



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
echo "IPAPASSWORD=$everyware_IPA_SECUREPASSWORD" > /opt/directory/etc/config

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
systemctl restart dbus # fix for certmonger error https://bugzilla.redhat.com/show_bug.cgi?id=1504688

ipa-server-install -a $everyware_IPA_SECUREPASSWORD --hostname $everyware_IPA_HOST --ip-address=$everyware_IPA_HOSTIP -r "$everyware_IPA_REALM" -p $everyware_IPA_SECUREPASSWORD -n "$everyware_IPA_DOMAIN" --no-ntp --setup-dns --forwarder="$everyware_IPA_DNS" --reverse-zone="$everyware_IPA_REVERSE.in-addr.arpa." --ssh-trust-dns --unattended

# Set resolv.conf
cat << EOF > /etc/resolv.conf
search $everyware_IPA_DOMAIN
nameserver 127.0.0.1
EOF

# Ensure PEERDNS=no in ifcfg-$everyware_PRIMARY_INTERFACE
sed '/^PEERDNS=/{h;s/=.*/=no/};${x;/^$/{s//PEERDNS=no/;H};x}' /etc/sysconfig/network-scripts/ifcfg-$everyware_PRIMARY_INTERFACE -i

echo $everyware_IPA_SECUREPASSWORD |kinit admin

ipa dnszone-add $everyware_CLUSTER1_NAME.$everyware_IPA_REALM_DOWNCASE
ipa dnszone-add $everyware_CLUSTER2_NAME.$everyware_IPA_REALM_DOWNCASE
ipa dnszone-add $everyware_CLUSTER3_NAME.$everyware_IPA_REALM_DOWNCASE
ipa dnszone-add $everyware_CLUSTER4_NAME.$everyware_IPA_REALM_DOWNCASE
ipa dnszone-add 100.10.in-addr.arpa.
