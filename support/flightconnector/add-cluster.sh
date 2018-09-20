############
# INDEXING #
############
EVERYWARE_ROOT="/opt/everyware"
EVERYWARE_CACHE="$EVERYWARE_ROOT/cache"
EVERYWARE_CACHEFILE="$EVERYWARE_CACHE/cache.txt"

if [ ! -d $EVERYWARE_CACHE ] ; then
    mkdir -p $EVERYWARE_CACHE
fi

if [ ! -f $EVERYWARE_CACHEFILE ] ; then
    cat << EOF > $EVERYWARE_CACHEFILE
NETWORK_INDEX: 1
VPN_INDEX: 11
EOF
fi

CLUSTER_INDEX="$(grep NETWORK_INDEX $EVERYWARE_CACHEFILE |awk '{print $2}')"
VPN_INDEX="$(grep VPN_INDEX $EVERYWARE_CACHEFILE |awk '{print $2}')"

CLUSTER_NETWORK_PREFIX="10.100.$CLUSTER_INDEX"
VPN_IP="10.78.110.$VPN_INDEX"

DOMAIN_NAME="$(hostname -d |sed 's/^[^.]*.//g')"

##############
# CHECK VARS #
##############

# The wrapper script for the blueprint yaml will export these variables.
# However if they are not set it will complain

help() {
    cat << EOF
To add a cluster using this script first export the relevant variables as explained below:
    CLUSTER_NAME = The name of the cluster (e.g. export CLUSTER_NAME="cluster1")
    LOGIN_NODE = The name of the login node (e.g. export LOGIN_NODE="cluster1-login1")
    GROUPS = A space separated list of primary node groups (e.g. export GROUPS="login nodes gpu")
        <GROUP NAME>_NODES = A space separated list of nodes for each of the above groups (e.g.
            export nodes_NODES="cluster1-node01 cluster1-node02 cluster1-node03 cluster1-node04 cluster1-node05"
            export gpu_NODES="cluster1-gpu01 cluster1-gpu02")
        <GROUP NAME>_SEC_GROUPS [OPTIONAL] = A space separated list of secondary groups for the nodes to be in (e.g.
            export nodes_SEC_GROUPS = 'compute'
            export gpu_SEC_GROUPS = 'compute')

IT IS IMPORTANT THAT THE NODENAMES ARE PREPENDED BY THE CLUSTERNAME AND A DASH FOR METALWARE TO PROPERLY CONFIGURE THE NODES.
EOF
}


for variable in CLUSTER_NAME LOGIN_NODE GROUPS ; do
    if [ -z ${!variable+x} ] ; then
        echo "$variable is unset, export before continuing"
        echo
        help
        exit 1
    fi
done

for group in $(echo $GROUPS) ; do
    # Check for nodes
    VAR="${group}_NODES"
    if [ -z ${!VAR+x} ] ; then
        echo "$VAR is unset, set this to a space-separated list of nodenames for the group"
        echo
        help
        exit 1
    fi
done


#################
# OPENVPN SETUP #
#################
./easyrsa --req-cn=$CLUSTER_NAME gen-req $CLUSTER_NAME nopass
./easyrsa sign-req client $CLUSTER_NAME

echo "route $CLUSTER_NETWORK_PREFIX.0 255.255.255.0 $VPN_IP" >> /etc/openvpn/flightconnector.conf

for file in $(ls /etc/openvpn/ccd-clusters) ; do
    echo "push \"route $CLUSTER_NETWORK_PREFIX.0 255.255.255.0 $VPN_IP\"" >> /etc/openvpn/ccd-clusters/$file
done

cat << EOF > /etc/openvpn/ccd-clusters/$CLUSTER_NAME
ifconfig-push $VPN_IP 255.255.255.0
push "route 10.78.100.0 255.255.255.0 10.78.110.1"
$(grep push $EVERYWARE_CACHEFILE |grep -v "$CLUSTER_NAME:" |sed 's/.*: //g')
iroute $CLUSTER_NETWORK_PREFIX.0 255.255.255.0
EOF

bash /etc/openvpn/buildinstaller.sh $CLUSTER_NAME

systemctl restart openvpn@flightconnector


#############
# METALWARE #
#############

# Configure login node group
metal configure group $CLUSTER_NAME-$login --answers \
    "{ \"genders_host_range\": \"$LOGIN_NODE\", \
    \"genders_additional_groups\": \"$CLUSTER_NAME\", \
    \"genders_all_group\": true, \
    \"pri_network_ip\": \"$CLUSTER_NETWORK_PREFIX.10\", \
    \"pri_network_gateway\": \"$CLUSTER_NETWORK_PREFIX.1\", \
    \"pri_network_domain\": \"$CLUSTER_NAME\"}"

# When adding multiple nodes node.index is not going to work for the subnet so offset by node count
# This starts at 10 as the login node will be .10 so first node will be .11
GROUP_STEP=10

for group in $(echo $GROUPS) ; do
    NODES="${group}_NODES"
    SEC_GROUPS="${group}_SEC_GROUPS"
    metal configure group $CLUSTER_NAME-$group --answers \
        "{ \"genders_host_range\": \"${!NODES}\", \
        \"genders_additional_groups\": \"$CLUSTER_NAME,$(echo ${!SEC_GROUPS}|sed 's/ /,/g')\", \
        \"genders_all_group\": true, \
        \"pri_network_ip\": \"$CLUSTER_NETWORK_PREFIX.<%= node.index + $GROUP_STEP %>\", \
        \"pri_network_gateway\": \"$CLUSTER_NETWORK_PREFIX.10\", \
        \"pri_network_domain\": \"$CLUSTER_NAME\"}"

    metal sync

    # Increase the value to be added to the index
    NODECOUNT=$(echo ${!NODES} |wc -w)
    GROUP_STEP=$(( GROUP_STEP + NODECOUNT ))
    echo "GROUP_STEP increased by $NODECOUNT to $GROUP_STEP"
done

# Template and sync local so that /etc/hosts is updated
metal template local && metal sync


#######
# IPA #
#######
IPA_PASS_SECURE=$(grep 'IPA Secure Password' /root/details.txt |sed 's/.*: //g')
IPA_PASS_INSECURE=$(grep 'IPA Insecure Password' /root/details.txt |sed 's/.*: //g')

echo $IPA_PASS_SECURE |kinit admin

ipa dnszone-add $CLUSTER_NAME.$DOMAIN_NAME

# Add all the nodes
for group in $(echo $GROUPS) ; do
    NODES="${group}_NODES"
    for node in $(echo ${!NODES}) ; do
        ipa host-add $(echo $node |sed "s/$CLUSTER_NAME-//g").$CLUSTER_NAME.$DOMAIN_NAME --password="$IPA_PASS_INSECURE" --ip-address="$(gethostip -x $node)"
    done
done


#############
# CLOUDWARE #
#############
CLOUDWARE_DOMAIN="$CLUSTER_NAME-$(echo $DOMAIN_NAME |sed 's/\./\-/g')"

fc domain create -t domainU --cluster-index $CLUSTER_INDEX --networkcidr $CLUSTER_NETWORK_PREFIX.0/24 --prisubnetcidr $CLUSTER_NETWORK_PREFIX.0/24 $CLOUDWARE_DOMAIN

sleep 5

fc machine create --domain $CLOUDWARE_DOMAIN --role login --cluster-index $CLUSTER_INDEX --priip $CLUSTER_NETWORK_PREFIX.10 $LOGIN_NODE

sleep 60

LOGIN_NODE_IP="$(fc machine info -d $CLOUDWARE_DOMAIN $LOGIN_NODE |grep "External IP" |awk '{print $5}')"

################
# BUILD IT ALL #
################

ssh alces@$LOGIN_NODE_IP "sudo bash -l -s" -- < /root/install_$CLUSTER_NAME.run
ssh alces@$LOGIN_NODE_IP "sudo init 6"

sleep 60

metal template $CLUSTER_NAME-$LOGIN_NODE
metal sync
metal build $CLUSTER_NAME-$LOGIN_NODE &

ssh alces@$LOGIN_NODE_IP "curl http://10.78.100.10/metalware/basic/cluster1-login1 |sudo /bin/bash"
ssh alces@$LOGIN_NODE_IP "sudo init 6"

sleep 30

for group in $(echo $GROUPS) ; do
    NODES="${group}_NODES"
    for node in $(echo $NODES) ; do
        fc machine create --domain $CLOUDWARE_DOMAIN --role compute --cluster-index $CLUSTER_INDEX --priip $(gethostip -d $node) $node &
    done
done

wait

sleep 30

metal template -g all
metal sync

for group in $(echo $GROUPS) ; do
    metal build -g $CLUSTER_NAME-$group &
done

for group in $(echo $GROUPS) ; do
    NODES="${group}_NODES"
    for node in $(echo $NODES) ; do
        ssh alces@$node "curl http://10.78.100.10/metalware/basic/$node |sudo /bin/bash" &
    done
done

wait


############
# INDEXING #
############

CLUSTER_INDEX=$(( CLUSTER_INDEX + 1 ))
VPN_INDEX=$(( VPN_INDEX + 1 ))

sed -i "s/NETWORK_INDEX:.*/NETWORK_INDEX: $CLUSTER_INDEX/g;s/VPN_INDEX:.*/VPN_INDEX: $VPN_INDEX/g" $EVERYWARE_CACHEFILE

echo "$CLUSTER_NAME: push \"route $CLUSTER_NETWORK_PREFIX.0 255.255.255.0 $VPN_IP\"" >> $EVERYWARE_CACHEFILE

