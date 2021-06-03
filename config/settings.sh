#!/bin/sh
# hostname of the gateway - it must accept vxlan and DHCP traffic
# clients get it as env variable
GATEWAY_NAME="${gateway}"
# K8S DNS IP address
# clients get it as env variable
K8S_DNS_IPS="${K8S_DNS_ips}"

# Vxlan ID to use
VXLAN_ID="42"
# VXLAN need an /24 IP range not conflicting with K8S and local IP ranges
VXLAN_IP_NETWORK="172.16.0"
# Gateway IP within the VXLAN - client PODs will be routed through it
VXLAN_GATEWAY_IP="${VXLAN_IP_NETWORK}.1"
# Keep a range of IPs for static assignment in nat.conf
VXLAN_GATEWAY_FIRST_DYNAMIC_IP=20

# If using a VPN, interface name created by it
VPN_INTERFACE=tun0
# Prevent non VPN traffic to leave the gateway
VPN_BLOCK_OTHER_TRAFFIC=true
# Traffic to these IPs will be send through the K8S gateway
VPN_LOCAL_CIDRS="10.0.0.0/8 192.168.0.0/16"

# DNS queries to these domains will be resolved by K8S DNS instead of
# the default (typcally the VPN client changes it)
DNS_LOCAL_CIDRS="local"