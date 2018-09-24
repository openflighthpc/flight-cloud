#############
# VARIABLES #
#############
ROOT_PASSWORD="$(cat /dev/urandom |tr -dc 'a-zA-Z0-9' |fold -w 8 |head -1)"
IPA_PASS_SECURE="$(cat /dev/urandom |tr -dc 'a-zA-Z0-9' |fold -w 8 |head -1)"
IPA_PASS_INSECURE="$(cat /dev/urandom |tr -dc 'a-zA-Z0-9' |fold -w 8 |head -1)"
CLUSTER_NAME="$(hostname -d |awk -F. '{print $2}')"
SSH_KEY="$(head -n 1 .ssh/authorized_keys |sed 's/.* ssh-rsa/ssh-rsa/g' | sed 's/\//\\\//g')" # Escape slashes so sed doesn't break

cat << EOF > /root/details.txt
Root Pass: $ROOT_PASSWORD
IPA Secure Password: $IPA_PASS_SECURE
IPA Insecure Password: $IPA_PASS_INSECURE
EOF

#######
# VPN #
#######

cd /etc/openvpn/easyrsa

./easyrsa init-pki
./easyrsa --req-cn=cluster0 build-ca nopass

./easyrsa --req-cn=cluster0 gen-req cluster0 nopass
./easyrsa sign-req server cluster0

./easyrsa gen-dh
./easyrsa gen-crl
openvpn --genkey --secret ta.key

systemctl restart openvpn@flightconnector

#############
# METALWARE #
#############

sed -i "s/root_password: REPLACEME/root_password: $(openssl -1 passwd $ROOT_PASSWORD)/g;s/ipa_insecurepassword: REPLACEME/ipa_insecurepassword: $IPA_PASS_INSECURE/g;s/cluster_name: REPLACEME/cluster_name: $CLUSTER_NAME/g;s/root_ssh_key: REPLACEME/root_ssh_key: $SSH_KEY/g;s/ipa_servername: REPLACEME/ipa_servername: $(hostname -f)/g" /var/lib/metalware/answers/domain.yaml


# FIX THIS IN METLAWARE SO IT DOESN'T OVERWRITE
#
#metal configure domain --answers "{ \"cluster_name\": \"$CLUSTER_NAME\", \
#    \"root_password\": \"$(openssl -1 passwd $(cat /dev/urandom |tr -dc 'a-zA-Z0-0' |fold -w 8 |head -1))\", \
#    \"ipa_insecurepassword\": \"$everyware_IPA_INSECUREPASSWORD\" }"

metal template local
metal sync

metal build local

systemctl enable gmetad
systemctl start gmetad
cp -f /var/lib/metalware/rendered/local/files/repo/core/chrony.conf /etc/chrony.conf
systemctl restart chronyd

#######
# IPA #
#######

IPA_REALM=$(hostname -d |sed 's/^[^.]*.//g' |tr '[a-z]' '[A-Z]')
IPA_DOMAIN=$(hostname -d)
IPA_REVERSE=$(gethostip -d $(hostname) |awk -F. '{print $2"."$1}')

echo "cw_ACCESS_fqdn=$(hostname -f)" > /opt/directory/etc/access.rc
echo "IPAPASSWORD=$IPA_PASS_SECURE" > /opt/directory/etc/config

# Temporarily stop HTTP server to avoid error:
#   IPA requires port 8443 for PKI but it is currently in use.
systemctl stop httpd

ipa-server-install -a $IPA_PASS_SECURE --hostname $(hostname -f) --ip-address=10.78.100.10 -r "$IPA_REALM" -p $IPA_PASS_SECURE -n "$IPA_DOMAIN" --no-ntp --setup-dns --forwarder="10.78.100.2" --reverse-zone="$IPA_REVERSE.in-addr.arpa." --ssh-trust-dns --unattended

systemctl start httpd

cat << EOF > /etc/resolv.conf
search $IPA_DOMAIN
nameserver 127.0.0.1
EOF

echo "$IPA_PASS_SECURE" |kinit admin

ipa group-add ClusterUsers --desc="Generic Cluster Users"
ipa config-mod --defaultshell /bin/bash
ipa config-mod --homedirectory /users
ipa config-mod --defaultgroup ClusterUsers
ipa pwpolicy-mod --maxlife=999

ipa hbacrule-disable allow_all
ipa hbacrule-add siteaccess --desc "Allow admin access to admin hosts"
ipa hbacrule-add useraccess --desc "Allow user access to user hosts"
ipa hbacrule-add-service siteaccess --hbacsvcs sshd
ipa hbacrule-add-service useraccess --hbacsvcs sshd
ipa hbacrule-add-user siteaccess --groups AdminUsers
ipa hbacrule-add-user useraccess --groups ClusterUsers
ipa hbacrule-add-host siteaccess --hostgroups adminnodes
ipa hbacrule-add-host useraccess --hostgroups usernodes

ipa sudorule-add --cmdcat=all All
ipa sudorule-add-user --groups=adminusers All
ipa sudorule-mod All --hostcat='all'
ipa sudorule-add-option All --sudooption '!authenticate'
ipa sudorule-add --cmdcat=all Site
ipa sudorule-add-user --groups=siteadmins Site
ipa sudorule-mod Site --hostcat=''
ipa sudorule-add-option Site --sudooption '!authenticate'
ipa sudorule-add-host Site --hostgroups=sitenodes

ipa dnszone-add 100.10.in-addr.arpa.

#############
# CLOUDWARE #
#############

cat << EOF > ~/.flightconnector.yml
general:
  log_file: '/var/log/cloudware.log'
provider:
  azure:
    tenant_id: '<insert your tenant ID here>'
    subscription_id: '<insert your subscription ID here>'
    client_secret: '<insert your client secret here>'
    client_id: '<insert your client ID here>'
  aws:
    access_key_id: '<insert your access key here>'
    secret_access_key: '<insert your secret key here>'
default:
  provider: aws
  region: eu-west-1
EOF

############
# MESSAGES #
############
echo
echo "#########################################################"
echo "The configuration has completed, now manually:"
echo "  - Reboot this machine"
echo "  - Copy the ssh-key used to access this server to /root/.ssh/id_rsa"
echo "  - Update /root/.flightconnector.yml"
echo "#########################################################"
echo
