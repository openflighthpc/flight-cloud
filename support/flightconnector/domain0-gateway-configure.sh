#############
# VARIABLES #
#############
ROOT_PASSWORD="$(cat /dev/urandom |tr -dc 'a-zA-Z0-9' |fold -w 8 |head -1)"
IPA_PASS_SECURE="$(cat /dev/urandom |tr -dc 'a-zA-Z0-9' |fold -w 8 |head -1)"
IPA_PASS_INSECURE="$(cat /dev/urandom |tr -dc 'a-zA-Z0-9' |fold -w 8 |head -1)"

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

sed -i "s/root_password: REPLACEME/root_password: $ROOT_PASSWORD/g;s/ipa_insecurepassword: REPLACEME/ipa_insecurepassword: $IPA_PASS_INSECURE/g" /var/lib/metalware/answers/domain.yaml


# FIX THIS IN METLAWARE SO IT DOESN'T OVERWRITE
#
#metal configure domain --answers "{ \"cluster_name\": \"$CLUSTER_NAME\", \
#    \"root_password\": \"$(openssl -1 passwd $(cat /dev/urandom |tr -dc 'a-zA-Z0-0'      |fold -w 8 |head -1))\", \
#    \"ipa_insecurepassword\": \"$everyware_IPA_INSECUREPASSWORD\" }"

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

IPA_REALM=$(hostname -d |sed 's/^[^.]*.//g' |tr '[a-z]' '[A-Z]')
IPA_DOMAIN=$(hostname -d)
IPA_REVERSE=$(hostname -d |sed 's/^[^.]*.//g' |tr '[a-z]' '[A-Z]')

echo "cw_ACCESS_fqdn=$(hostname -f)" > /opt/directory/etc/access.rc
echo "IPAPASSWORD=$IPA_PASS_SECURE" > /opt/directory/etc/config

ipa-server-install -a $IPA_PASS_SECURE --hostname $(hostname -f) --ip-address=10.78.100.10 -r "$IPA_REALM" -p $IPA_PASS_SECURE -n "$IPA_DOMAIN" --no-ntp --setup-dns --forwarder="10.78.100.2" --reverse-zone="$IPA_REVERSE.in-addr.arpa." --ssh-trust-dns --unattended

cat << EOF > /etc/resolv.conf
search $IPA_DOMAIN
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
