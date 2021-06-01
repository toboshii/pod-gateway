#!/bin/sh -ex

#Load main settings
cat /config/settings.sh
. /config/settings.sh

#in re-entry we need to remove the vxlan
#on first entry set a routing rule to the k8s DNS server
if ip addr|grep -q vxlan0; then
  ip link del vxlan0
fi



K8S_GW_ROUTE=$(ip route get ${DNS_ORG}|head -1)
K8S_GW_ROUTE=${K8S_GW_ROUTE%%uid*}
ip route add $K8S_GW_ROUTE || /bin/true

#Delete default GW to prevent outgoing traffic to leave this docker
echo "Deleting existing default GWs"
ip route del 0/0 || /bin/true


#After this point nothing should be reachable -> check
if ping -c 1 -W 1000 8.8.8.8; then
  echo "WE SHOULD NOT BE ABLE TO PING -> EXIT"
  exit 255
fi

#derived settings
OPENVPN_ROUTER_IP="$(dig +short $OPENVPN_ROUTER_NAME @${DNS_ORG})"
GW_ORG=$(route |awk '$1=="default"{print $2}')
NAT_ENTRY="$(grep $(hostname) /config/nat.conf||true)"

#Create tunnel NIC
ip link add vxlan0 type vxlan id $VXLAN_ID dev eth0 dstport 0 || true
bridge fdb append to 00:00:00:00:00:00 dst $OPENVPN_ROUTER_IP dev vxlan0
ip link set up dev vxlan0

#Configure IP and default GW though the VPN docker
if [ -z "$NAT_ENTRY" ]; then
  echo "Get dynamic IP"
  dhclient -cf /config/dhclient.conf vxlan0
else
  IP=$(echo $NAT_ENTRY|cut -d' ' -f2)
  VXLAN_IP="${VXLAN_IP_NETWORK}.${IP}"
  echo "Use fixed IP $VXLAN_IP"
  ip addr add $VXLAN_IP/24 dev vxlan0
  route add default gw $VXLAN_ROUTER_IP
  echo "nameserver $VXLAN_ROUTER_IP">/etc/resolv.conf.dhclient
fi
ping -c1 $VXLAN_ROUTER_IP

#Set DNS
#route add $DNS_ORG gw $GW_ORG
cp -av /etc/resolv.conf.dhclient* /etc_shared/resolv.conf

FIRST_BOOT_MARKER=/etc_shared/booted
if [ ! -e "$FIRST_BOOT_MARKER" ] || [ -n "$FIRST_BOOT" ]; then
  touch $FIRST_BOOT_MARKER
  echo "First boot (init container): ending now."
  exit 0
else
  echo "Not first boot: stay on monitoring connection to VPN"
  while true; do
    # Sleep while reacting to signals
    sleep 600 &
    wait $!
    #Ping router
    ping -c1 $VXLAN_ROUTER_IP
  done
fi
