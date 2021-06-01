#!/bin/sh -ex

cat /config/settings.sh
. /config/settings.sh

#Block default output traffic
iptables --policy OUTPUT DROP

#create config
echo "interface=vxlan0
bind-interfaces
dhcp-range=${VXLAN_IP_NETWORK}.20,${VXLAN_IP_NETWORK}.200,12h
server=/local/${DNS_ORG}">>/etc/dnsmasq.conf

#Need to wait until new DNS server in /etc/resolv.conf is setup
#TBD: find a better way
sleep 10

exec dnsmasq -k
