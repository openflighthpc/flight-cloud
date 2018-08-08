#!/bin/bash

#################
# PREREQUISITES #
#################
yum install -y syslinux git httpd epel-release ipa-server bind bind-dyndb-ldap ipa-server-dns firefox
yum install -y openvpn easy-rsa
yum update -y

firewall-cmd --add-service ldap --add-service ldaps --add-service kerberos\
    --add-service kpasswd --add-service http --add-service https\
    --add-service dns --add-service mountd --add-service nfs\
    --add-service ntp --add-service syslog\
    --zone external --permanent

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
everyware_IPA_REALM_DOWNCASE="${everyware_IPA_REALM:-$(hostname -d |sed 's/^[^.]*.//g')}"
everyware_IPA_DOMAIN="${everyware_IPA_DOMAIN:-$(hostname -d)}"
everyware_IPA_DNS="${everyware_IPA_DNS:-8.8.8.8}"
everyware_IPA_REVERSE="${everyware_IPA_REVERSE:-$(gethostip -d $(hostname) |awk -F. '{print $2"."$1}')}"

if [ $everyware_IPA_PASSWORD == "REPLACE_ME" ] ; then
    echo "The IPA password needs to be provided as a CLI argument"
    echo "To do this when curling the script:"
    echo "  curl http://path/to/domain0-gateway.sh |everyware_IPA_PASSWORD=MySecurePassword /bin/bash"
    exit 1
fi

# IPA Server Install
systemctl restart dbus # fix for certmonger error https://bugzilla.redhat.com/show_bug.cgi?id=1504688

ipa-server-install -a $everyware_IPA_PASSWORD --hostname $everyware_IPA_HOST --ip-address=$everyware_IPA_HOSTIP -r "$everyware_IPA_REALM" -p $everyware_IPA_PASSWORD -n "$everyware_IPA_DOMAIN" --no-ntp --setup-dns --forwarder="$everyware_IPA_DNS" --reverse-zone="$everyware_IPA_REVERSE.in-addr.arpa." --ssh-trust-dns --unattended


#echo $everyware_IPA_PASSWORD |kinit admin

#ipa dnszone-add cluster1.$everyware_IPA_REALM_DOWNCASE
#ipa dnszone-add cluster2.$everyware_IPA_REALM_DOWNCASE
#ipa dnszone-add cluster3.$everyware_IPA_REALM_DOWNCASE
#ipa dnszone-add cluster4.$everyware_IPA_REALM_DOWNCASE
#ipa dnszone-add 100.10.in-addr.arpa.
