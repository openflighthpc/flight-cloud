####################
# INSTALL PACKAGES #
####################
yum install -y syslinux git httpd epel-release ipa-server bind bind-dyndb-ldap ipa-server-dns firefox
yum install -y openvpn easy-rsa
yum update -y

############
# FIREWALL #
############
systemctl disable iptables
systemctl enable firewalld
systemctl stop iptables
systemctl start firewalld
systemctl disable cloud-init
systemctl disable cloud-init-local
systemctl disable cloud-config
systemctl disable cloud-final

firewall-cmd --add-service ldap --add-service ldaps --add-service kerberos\
    --add-service kpasswd --add-service http --add-service https\
    --add-service dns --add-service mountd --add-service nfs\
    --add-service ntp --add-service syslog\
    --zone external --permanent

#################
# OPENVPN SETUP #
#################
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
set_var EASYRSA_BATCH           "true"
EOF

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
irewall-cmd --new-zone $CLUSTER --permanent
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

systemctl enable openvpn@flightconnector

firewall-cmd --new-zone cluster0 --permanent
firewall-cmd --add-interface tun0 --zone cluster0 --permanent
firewall-cmd --remove-interface eth0 --zone public
firewall-cmd --remove-interface eth0 --zone public --permanent
firewall-cmd --add-interface eth0 --zone external --permanent
firewall-cmd --add-interface eth0 --zone external
firewall-cmd --add-port 2005/tcp --zone external --permanent

firewall-cmd --set-target=ACCEPT --zone cluster0 --permanent

sed '/^ZONE=/{h;s/=.*/=external/};${x;/^$/{s//ZONE=external/;H};x}' /etc/sysconfig/network-scripts/ifcfg-eth0 -i

#############
# CLOUDWARE #
#############
curl -sL https://git.io/vbsTg | alces_OS=el7 alces_SOURCE_BRANCH=dev/everyware-minimalrepo /bin/bash

#############
# METALWARE #
#############
curl -sL http://git.io/metalware-installer |alces_OS=el7 alces_SOURCE_BRANCH=2018.4.0-rc1 /bin/bash
source /etc/profile.d/alces-metalware.sh
metal repo use https://github.com/alces-software/metalware-repo-base.git
cd /var/lib/metalware/repo/
git checkout dev/everyware-minimalrepo
mv plugins/* ../plugins/

metal configure domain --answers "{ \"metalware_internal--plugin_enabled--firstrun\": true, \
    \"cluster_name\": \"REPLACEME\", \
    \"root_password\": \"REPLACEME\", \
    \"root_ssh_key\": \"REPLACEME\", \
    \"metalware_internal--plugin_enabled--firstrun\": true, \
    \"metalware_internal--plugin_enabled--flightdirect\": false, \
    \"metalware_internal--plugin_enabled--flightcenter\": true, \
    \"metalware_internal--plugin_enabled--ganglia\": true, \
    \"ganglia_serverip\": \"10.78.100.10\", \
    \"metalware_internal--plugin_enabled--infiniband\": false, \
    \"metalware_internal--plugin_enabled--ipa\": true, \
    \"ipa_serverip\": \"10.78.100.10\", \
    \"ipa_servername\": \"gateway.dom0\", \
    \"ipa_userdir\": \"/users/\", \
    \"ipa_insecurepassword\": \"REPLACEME\", \
    \"metalware_internal--plugin_enabled--lustre\": false, \
    \"metalware_internal--plugin_enabled--nfs\": true, \
    \"nfs_isclient\": true, \
    \"metalware_internal--plugin_enabled--nvidia\": false, \
    \"metalware_internal--plugin_enabled--rootrun\": false, \
    \"metalware_internal--plugin_enabled--slurm\": false, \
    \"metalware_internal--plugin_enabled--yumrepo\": false }"

cat << EOF > /var/lib/metalware/repo/config/domain.yaml
cluster: '<%= answer.cluster_name %>'
# GENERATE with openssl passwd -1 \$PASSWD.
# XXX Change this so admin enters plain text root password, and we generate
# encrypted password here?
encrypted_root_password: '<%= answer.root_password %>'
profile: MASTER
ssh_key: '<%= answer.root_ssh_key %>'

# Generic networking properties.
domain: <%= answer.domain %>
cloudware_domain: 10.78.0.0
clusters_network: 10.100.0.0
search_domains: "<% config.networks.each do |network, details| -%><% next if network.to_s == 'ext' %><%= details.domain %><%= if network.to_s == 'bmc' then '.mgt' else '' end %>.<%= config.domain %> <% end -%><%= config.domain %>"
dns_type: "<%= answer.dns_type %>"
externaldns: 10.78.100.2
internaldns: 10.78.100.10
kernelappendoptions: "console=tty0 console=ttyS1,115200n8"
jobid: ""

networks:
  pri:
    defined: true
    interface: eth0
    hostname: "<%= config.networks.pri.short_hostname %>.<%= config.domain %>"
    domain: <%= answer.pri_network_domain %>
    short_hostname: "<%= node.name.sub(node.group.name + '-', '') %>.<%= config.networks.pri.domain %>"
    ip: <%= answer.pri_network_ip_node || "10.100.#{node.group.index}.#{node.index + 19}"%>
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

metal configure local --answers "{ \"pri_network_short_hostname\": \"gateway.dom0\", \
    \"ganglia_isserver\": true, \
    \"nfs_isserver\": true }"

cat << EOF > /var/lib/metalware/repo/config/local.yaml
networks:
  pri:
    defined: true
    ip: 10.78.100.10
    netmask: 255.255.0.0
    network: 10.78.0.0
    short_hostname: <%= answer.pri_network_short_hostname %>
    interface: eth0
    gateway: 10.78.100.1
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

#######
# IPA #
#######

# Install Userware
git clone https://github.com/alces-software/userware /tmp/userware
rsync -auv /tmp/userware/{directory,share} /opt/

cd /opt/directory/cli
make setup

mkdir /opt/directory/etc

mkdir -p /var/www/html/secure

# Branding
mkdir -p /opt/flight/bin
cd /opt/flight/bin
curl https://s3-eu-west-1.amazonaws.com/flightconnector/directory/resources/banner > banner
chmod 755 banner

cd /opt/directory/cli/bin
curl https://s3-eu-west-1.amazonaws.com/flightconnector/directory/resources/sandbox-starter > sandbox-starter

# IPA Admin User Config
useradd ipaadmin
su - ipaadmin -c "ssh-keygen -f /home/ipaadmin/.ssh/id_rsa -N ''"
cat << EOF > /home/ipaadmin/.ssh/authorized_keys
command="/opt/directory/cli/bin/sandbox-starter",no-port-forwarding,no-x11-forwarding,no-agent-forwarding $(cat /home/ipaadmin/.ssh/id_rsa.pub)
EOF
chown ipaadmin:ipaadmin /home/ipaadmin/.ssh/authorized_keys
chmod 600 /home/ipaadmin/.ssh/authorized_keys
passwd -l ipaadmin

echo 'AcceptEnv FC_*' >> /etc/ssh/sshd_config

# Ensure PEERDNS=no in ifcfg-$everyware_PRIMARY_INTERFACE
sed '/^PEERDNS=/{h;s/=.*/=no/};${x;/^$/{s//PEERDNS=no/;H};x}' /etc/sysconfig/network-scripts/ifcfg-eth0 -i
