#!/bin/sh -ex

cat /config/settings.sh
. /config/settings.sh

if [ "$BLOCK_NON_VPN_OUTPUT" = true ] ; then
    #Block default output traffic
    iptables --policy OUTPUT DROP
fi

#Get K8S DNS
K8S_DNS=$(grep nameserver /etc/resolv.conf|cut -d' ' -f2)

#create config
echo "
interface=vxlan0
bind-interfaces
dhcp-range=${VXLAN_IP_NETWORK}.20,${VXLAN_IP_NETWORK}.200,12h
server=/local/${K8S_DNS}

# For debugging purposes, log each DNS query as it passes through
# dnsmasq.
log-queries                                                 
                                                                
# Log lots of extra information about DHCP transactions.          
log-dhcp

# Log to stdout
log-facility=-
">>/etc/dnsmasq.conf

#Need to wait until new DNS server in /etc/resolv.conf is setup
#TBD: find a better way
sleep 10

exec dnsmasq -k
