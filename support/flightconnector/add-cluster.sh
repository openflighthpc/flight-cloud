#################
# OPENVPN SETUP #
#################
./easyrsa --req-cn=$everyware_CLUSTER1_NAME gen-req $everyware_CLUSTER1_NAME nopass
./easyrsa sign-req client $everyware_CLUSTER1_NAME

echo "route $everyware_CLUSTER1_NETWORK 255.255.255.0 10.78.110.11" >> /etc/openvpn/flightconnector.conf

cat << EOF > /etc/openvpn/ccd-clusters/$everyware_CLUSTER1_NAME
ifconfig-push $VPN_IP 255.255.255.0
# $FOR $ALL $OTHER $NETWORKS
push "route $THATCLUSTERNETWORK 255.255.255.0 $THATVPNIP"
iroute $everyware_CLUSTER1_NETWORK 255.255.255.0
EOF

# TODO

bash /etc/openvpn/buildinstaller.sh $everyware_CLUSTER1_NAME

#######
# IPA #
#######

echo $everyware_IPA_SECUREPASSWORD |kinit admin

ipa dnszone-add $everyware_CLUSTER1_NAME.$everyware_IPA_REALM_DOWNCASE

# TODO Add all the nodes $BLUEPRINT_NODE_LIST


#############
# METALWARE #
#############
metal configure group $everyware_CLUSTER1_NAME --answers \
    "{ \"genders_host_range\": \"$BLUEPRINT_NODE_LIST\", \
    \"genders_additional_groups\": \"$BLUEPRINT_SEC_GROUPS\", \
    \"genders_all_group\": true, \
    \"pri_network_domain\": \"$everyware_CLUSTER1_NAME\" }"

metal sync

metal configure node $everyware_CLUSTER1_NAME-$BLUEPRINT_NAME --answers \
    "{ \"pri_network_ip_node\": \"10.100.<%= node.group.index %>.10\", \
    \"pri_network_gateway\": \"10.100.<%= node.group.index %>.1\" }"


#############
# CLOUDWARE #
#############

fc domain create -t domainU --cluster-index 1 --networkcidr 10.100.1.0/24 --prisubnetcidr 10.100.1.0/24 cluster1-aang-alces-network

# WAIT

fc machine create --domain cluster1-aang-alces-network --role login --cluster-index 1 --priip 10.100.1.10 login1

# WAIT

################
# BUILD IT ALL #
################

ssh cluster1-login1 "bash -l -s" -- < install_cluster1.run

metal template cluster1-login1
metal sync
metal build cluster1-login1 &

ssh cluster1-login1 "curl http://10.78.100.10/metalware/basic/cluster1-login1 |/bin/bash"

wait

for node in $BLUEPRINT_NODE_LIST ; do
    fc machine create --domain cluster1-aang-alces-network --role compute --cluster-index 1 --priip 10.100.1.21 node01
done

# WAIT

metal template -g all
metal sync

for group in $PRIMARY_GROUPS_EXCLUDING_LOGIN1 ; do
    metal build -g $group &
done

for node in $BLUEPRINT_NODE_LIST ; do
    ssh $node "curl http://10.78.100.10/metalware/basic/$CLUSTER_NAME-$NODE |/bin/bash"
done

wait

