#!/bin/bash
### BEGIN INIT INFO
# Provides:          custom firewall
# Required-Start:    $remote_fs $syslog $network
# Required-Stop:     $remote_fs $syslog $network
# Default-Start:	2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: firewall initscript
# Description:       Custom Firewall
### END INIT INFO

# iptables lookup
iptables=$(which iptables)
ip6tables=$(which ip6tables)

# setup network device
device="eth0 wlan0"

# stop if iptables is not found
test -f "$iptables" || exit 0
test -f "$ip6tables" || exit 0

case "$1" in
  start)
    echo "Setting up iptables and ip6tables..."

    # flush tables
    iptables -F
    iptables -t nat -F
    iptables -t mangle -F
    iptables -X
    iptables -t nat -X
    iptables -t mangle -X
    
    ip6tables -F
    ip6tables -t nat -F
    ip6tables -t mangle -F
    ip6tables -X
    ip6tables -t nat -X
    ip6tables -t mangle -X    

    # set default policies
    iptables -P INPUT DROP
    iptables -P OUTPUT DROP
    iptables -P FORWARD DROP
    
    ip6tables -P INPUT DROP
    ip6tables -P OUTPUT DROP
    ip6tables -P FORWARD DROP    

    # MY_REJECT chain
    iptables -N MY_REJECT
    ip6tables -N MY_REJECT6

    # MY_DROP chain
    iptables -N MY_DROP
    iptables -A MY_DROP -j DROP
    
    ip6tables -N MY_DROP6
    ip6tables -A MY_DROP6 -j DROP    

    # drop invalid packages
    iptables -A INPUT -m state --state INVALID -j DROP
    iptables -A OUTPUT -m state --state INVALID -j DROP
    
    ip6tables -A INPUT -m state --state INVALID -j DROP
    ip6tables -A OUTPUT -m state --state INVALID -j DROP
    
    # allow loopback device traffic
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    ip6tables -A INPUT -i lo -j ACCEPT
    ip6tables -A OUTPUT -o lo -j ACCEPT

    # set tracking of connection
    iptables -A OUTPUT -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

    ip6tables -A OUTPUT -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
    ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # allow ICMP ping
    # iptables -A INPUT -p icmp -j ACCEPT
    # ip6tables -A INPUT -p ipv6-icmp -j ACCEPT

# multiple interface FW rules
for i in $device
 do

	# allow SSH default port
	iptables -A INPUT -i $i -m state --state NEW -p tcp --dport 22 -j ACCEPT

    # set default policies REJECT
    iptables -A INPUT -j MY_REJECT
    iptables -A OUTPUT -j MY_REJECT
    
    ip6tables -A INPUT -j MY_REJECT6
    ip6tables -A OUTPUT -j MY_REJECT6    
    ;;

  stop)
    echo "Cleaning iptables and ip6tables rules"
    # flush tabelles
    iptables -F
    iptables -t nat -F
    iptables -t mangle -F
    iptables -X
    iptables -t nat -X
    iptables -t mangle -X
    
    ip6tables -F
    ip6tables -t nat -F
    ip6tables -t mangle -F
    ip6tables -X
    ip6tables -t nat -X
    ip6tables -t mangle -X    
    
    # set default policies
    iptables -P INPUT ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -P FORWARD ACCEPT
    
    ip6tables -P INPUT ACCEPT
    ip6tables -P OUTPUT ACCEPT
    ip6tables -P FORWARD ACCEPT    
    ;;

  restart)
    echo "Restarting iptables and ip6tables..."
    $0 stop
    $0 start
    ;;

  status)
    echo "Rule list of iptables and ip6tables:"
    iptables -L -vn
    ip6tables -L -vn
    echo "nat table"
    iptables -t nat -L -vn
    ip6tables -t nat -L -vn
    echo "mangle table"
    iptables -t mangle -L -vn
    ip6tables -t mangle -L -vn
    ;;

  *)
    echo "Syntax of firewall:"
    echo "Syntax: $0 {start|stop|status}"
    exit 1
    ;;

esac

exit 0
