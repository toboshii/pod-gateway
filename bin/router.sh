#!/bin/sh -ex

cat /config/settings.sh
. /config/settings.sh

#Create tunnel NIC
ip link add vxlan0 type vxlan id $VXLAN_ID  dev eth0 dstport 0 || true
ip addr add ${VXLAN_GATEWAY_IP}/24 dev vxlan0 || true
ip link set up dev vxlan0

#Enable outbound NAT
iptables -t nat -A POSTROUTING -j MASQUERADE

#Open inbond NAT ports
while read aLine; do
  case "$aLine" in
    \#*) continue;;
    *) echo Processing: $aLine ;;
  esac
  #Skip lines with comments
  [[ '$aLine' == \#* ]] && continue
  NAME=$(echo $aLine|cut -d' ' -f1)
  IP=$(echo $aLine|cut -d' ' -f2)
  PORTS=$(echo $aLine|cut -d' ' -f3)
  #Add NAT entries
  for portStr in $(echo $PORTS|sed 's/,/ /g'); do
    PORT_TYPE=$(echo $portStr|cut -d':' -f1)
    PORT_NUMBER=$(echo $portStr|cut -d':' -f2)
    echo "IP: $IP , NAME: $NAME , PORT: $PORT_NUMBER , TYPE: $PORT_TYPE"
    iptables -t nat -A PREROUTING -p ${PORT_TYPE} -i tun0 --dport ${PORT_NUMBER} -j DNAT --to-destination ${VXLAN_IP_NETWORK}.${IP}:${PORT_NUMBER}
    iptables -A FORWARD -p ${PORT_TYPE} -d ${VXLAN_IP_NETWORK}.${IP} --dport ${PORT_NUMBER} -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
  done
done </config/nat.conf

#Firewall incomming traffic from VPN
echo Accept traffic alredy ESTABLISHED
iptables -A FORWARD -i tun0 -m state --state ESTABLISHED,RELATED -j ACCEPT
echo "Reject other traffic"
iptables -A FORWARD -i tun0 -j REJECT
#iptables -A INPUT -i tun0 -j REJECT

if [ "$BLOCK_NON_VPN_OUTPUT" = true ] ; then
  # Do not forward any traffic that does not leave through tun0
  # The openvpn will also add drop rules but this is to ensure we block even if VPN is not connecting
  iptables --policy FORWARD DROP
  iptables -I FORWARD -o tun0 -j ACCEPT

  #Do not allow outbound traffic on eth0 beyond VPN and local traffic
  iptables --policy OUTPUT DROP
  iptables -A OUTPUT -p udp --dport 443 -j ACCEPT #VPN traffic over UDP
  iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT #VPN traffic over TCP
  iptables -A OUTPUT -d 10.0.0.0/8  -j ACCEPT
  iptables -A OUTPUT -d 192.168.0.0/16  -j ACCEPT
  iptables -A OUTPUT -o tun0 -j ACCEPT
  iptables -A OUTPUT -o vxlan0 -j ACCEPT
fi

#Routes for local networks
GW_IP=$(/sbin/ip route | awk '/default/ { print $3 }')
#ip route add 10.0.0.0/8 via ${GW_IP}
ip route add 192.168.0.0/16 via ${GW_IP}
