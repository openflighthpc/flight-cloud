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
metal configure domain --answers "{ \"cluster_name\": \"$CLUSTER_NAME\", \
    \"root_password\": \"$ROOT_PASSWORD\", \
    \"externaldns\": \"$IP_FROM_RESOLVCONF\", \
    \"ipa_serverip\": \"$everyware_IPA_HOSTIP\", \
    \"ipa_insecurepassword\": \"$everyware_IPA_INSECUREPASSWORD\" }"

metal sync

metal template local
metal sync

metal build local

systemctl enable gmetad
systemctl start gmetad
cp /var/lib/metalware/rendered/local/files/repo/core/chrony.conf /etc/chrony.conf
systemctl restart chronyd

#######
# IPA #
#######

echo "cw_ACCESS_fqdn=$(hostname -f)" > /opt/directory/etc/access.rc
echo "IPAPASSWORD=$everyware_IPA_SECUREPASSWORD" > /opt/directory/etc/config

ipa-server-install -a $everyware_IPA_SECUREPASSWORD --hostname $everyware_IPA_HOST --ip-address=$everyware_IPA_HOSTIP -r "$everyware_IPA_REALM" -p $everyware_IPA_SECUREPASSWORD -n "$everyware_IPA_DOMAIN" --no-ntp --setup-dns --forwarder="$everyware_IPA_DNS" --reverse-zone="$everyware_IPA_REVERSE.in-addr.arpa." --ssh-trust-dns --unattended

cat << EOF > /etc/resolv.conf
search $everyware_IPA_DOMAIN
nameserver 127.0.0.1
EOF

#############
# CLOUDWARE #
#############

cat << EOF > ~/.flightconnector.yml
general
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
echo "  - Update /root/.flightconnector.yml"
echo "#########################################################"
echo
