#!/bin/sh
#################################################################################################
#   Description: Create firewall on JianFeng Gate. 
#                1) All persons may access Wan
#                2) Use IP MASQUERADE 
#                3) Use DMZ
#                4) The three subnet use the three NIC on gate host
#                5) CCI and JianFeng subnets may access file server.
#
#	eth0   10.1.1.3/24     China CCI Sub Network 
#	eth1   192.168.1.1/24  route 192.168.1.1, DMZ For Wan Servers 
#              192.168.2.10/24 The subnet is a internal DMZ 
#                              for internal services
#	eth2   218.107.142.181   GW route 210.82.112.126, 32 Wan hosts
#	eth0   172.16.1.1/24      Duanzj Project Group
#              172.16.6.1/24      JianFeng Administration Department And JianFeng China Sub Network
#              172.18.10.1/24     US. CAI Project group
#              172.32.16.1/24     ZhiKaZhongXing
#              172.32.17.1/24     FaGuiZhongXing
#                                 USA CAI LAN: 192.168.0.x
#                                 China CAI LAN: 172.18.10.6
#	       172.16.8.1/24      PD(English) Project Group
#	eth4   172.16.2.1/24      JF Lancelot subnet; PCTS
#                                 USA PCTS LAN: 10.0.4.x
#				  China PCTS LAN: 172.16.2.5
#       eth6   172.18.1.1/24   Yang De Si Te Subnet; 172.18.1.1
#	eth0   202.205.9.168   CerNet international entrance
#
#       3 layer switch: 10.10.10.1
#            GW eth1:3: 10.10.10.2
#
#       IPs Address Range: 10.X.X.X; 192.168.X.X; 172.16~31.X.X
#
#################################################################################################

#####################################################################
#
# Add static routes for 3 layer switch
#
#####################################################################

cat /etc/firewall/route_tab|grep -v "^#"|grep "^-"|while read ru
do
/sbin/route del $ru
/sbin/route add $ru
done

################################################################################
# ENV variables
################################################################################
IPT=/sbin/iptables;export IPT
MP=/sbin/modprobe;export MP

#echo "Begin to start the firewall ..."

################################################################################
# set some system kernel parameters
################################################################################
echo 1 >/proc/sys/net/ipv4/conf/default/log_martians
echo 0 >/proc/sys/net/ipv4/conf/default/rp_filter
echo 1 >/proc/sys/net/ipv4/conf/eth1/log_martians
# comment for 3 layer switch
#echo 1 >/proc/sys/net/ipv4/conf/eth0/log_martians
echo 1 >/proc/sys/net/ipv4/conf/eth0/log_martians
echo 1 >/proc/sys/net/ipv4/conf/eth2/log_martians
echo 1 > /proc/sys/net/ipv4/ip_forward
# comment for 3 layer switch
#echo 0 >/proc/sys/net/ipv4/conf/eth0/rp_filter
echo 0 >/proc/sys/net/ipv4/conf/eth0/rp_filter 
echo 0 >/proc/sys/net/ipv4/conf/eth1/rp_filter
echo 0 >/proc/sys/net/ipv4/conf/eth2/rp_filter

# $IPT command
$IPT -F
$IPT -t nat -F
$IPT --delete-chain
$IPT -t nat --delete-chain
$MP ip_tables
$MP iptable_nat
$MP iptable_filter
$MP ip_conntrack_ftp
$MP ip_nat_ftp
$MP ipt_state
$MP ipt_MASQUERADE
# For openvpn
$MP tun

$IPT -P INPUT ACCEPT
$IPT -P OUTPUT ACCEPT
$IPT -P FORWARD ACCEPT

$IPT -P INPUT DROP
$IPT -P OUTPUT DROP
$IPT -P FORWARD DROP

########################################################################################
##
## Use eth1table route to international
##
########################################################################################
# Comment for 3 layer switch
/sbin/ip route delete 10.1.0.0/16 via 10.10.10.1 table eth1table
/sbin/ip route add 10.1.0.0/16 via 10.10.10.1 table eth1table 
/sbin/ip ru del to 10.1.1.1/16 pref 200 table eth1table
/sbin/ip ru add to 10.1.1.1/16 pref 200 table eth1table
#PD
/sbin/ip route delete 172.16.8.0/24 via 10.10.10.1 table eth1table
/sbin/ip route add 172.16.8.0/24 via 10.10.10.1 table eth1table
/sbin/ip ru del to 172.16.8.1/24 pref 200 table eth1table
/sbin/ip ru add to 172.16.8.1/24 pref 200 table eth1table
#PCTS
/sbin/ip route delete 172.16.2.0/24 via 10.10.10.1 table eth1table
/sbin/ip route add 172.16.2.0/24 via 10.10.10.1 table eth1table
/sbin/ip ru del to 172.16.2.1/24 pref 200 table eth1table
/sbin/ip ru add to 172.16.2.1/24 pref 200 table eth1table
#XinZheng
/sbin/ip route delete 172.16.6.0/24 via 10.10.10.1 table eth1table
/sbin/ip route add 172.16.6.0/24 via 10.10.10.1 table eth1table
/sbin/ip ru del to 172.16.6.1/24 pref 200 table eth1table
/sbin/ip ru add to 172.16.6.1/24 pref 200 table eth1table
#XinShiYeBu
/sbin/ip route delete 172.18.10.0/24 via 10.10.10.1 table eth1table
/sbin/ip route add 172.18.10.0/24 via 10.10.10.1 table eth1table
/sbin/ip ru del to 172.18.10.1/24 pref 200 table eth1table
/sbin/ip ru add to 172.18.10.1/24 pref 200 table eth1table


#/sbin/ip route delete  10.224.20.0/22 via 10.1.1.126 table eth1table
#/sbin/ip route add  10.224.20.0/22 via 10.1.1.126 table eth1table

# For GuanHuanXinWang: eth0 
/sbin/ip route del default via 220.231.38.193 table eth0table 
/sbin/ip route add default via 220.231.38.193 table eth0table
#ip ru del from 220.231.38.193/28 table eth0table prio 240
#ip ru add from 220.231.38.193/28 table eth0table prio 240 
#ip ru del to 220.231.38.193/28 table eth0table prio 240
#ip ru add to 220.231.38.193/28 table eth0table prio 240

# For DianXinTong : eth2
/sbin/ip route del default via 124.207.105.225 table eth2table
/sbin/ip route add default via 124.207.105.225 table eth2table
/sbin/ip ru del to 65.223.51.68/24 pref 200 table eth2table
/sbin/ip ru add to 65.223.51.68/24 pref 200 table eth2table
/sbin/ip ru del from 124.207.105.224/27 table eth2table prio 240
/sbin/ip ru add from 124.207.105.224/27 table eth2table prio 240 
/sbin/ip ru del to 124.207.105.224/27 table eth2table prio 240
/sbin/ip ru add to 124.207.105.224/27 table eth2table prio 240

## For PD group
#ip route del from 172.16.8.0/24 table eth2table 240 
#ip route add from 172.16.8.0/24 table eth2table 240
#ip route del default via 121.207.105.225 dev eth2 table eth2table
#ip route add default via 124.207.105.225 dev eth2 table eth2table

# For IPs into eth2: eth2
for eth2ip in `cat /etc/eth2list`
do
/sbin/ip rule del from $eth2ip pref 500 table eth2table
/sbin/ip rule add from $eth2ip pref 500 table eth2table
done

# For Lan Network: eth1
# For put common zone to 3 layer switch
/sbin/ip route del 192.168.2.0/24 via 10.10.10.1 table eth1table
/sbin/ip route add 192.168.2.0/24 via 10.10.10.1 table eth1table
/sbin/ip rule del from 192.168.2.0/24 table eth1table prio 220
/sbin/ip rule add from 192.168.2.0/24 table eth1table prio 220
/sbin/ip rule del to 192.168.2.0/24 table eth1table prio 220
/sbin/ip rule add to 192.168.2.0/24 table eth1table prio 220
#DMZ zone
/sbin/ip route delete 192.168.1.0/24 via 192.168.1.1 table eth1table
/sbin/ip route add 192.168.1.0/24 via 192.168.1.1 table eth1table
/sbin/ip rule del from 192.168.1.0/24 table eth1table prio 210
/sbin/ip rule add from 192.168.1.0/24 table eth1table prio 210
/sbin/ip rule del to 192.168.1.0/24 table eth1table prio 210
/sbin/ip rule add to 192.168.1.0/24 table eth1table prio 210


#Flush route
/sbin/ip route flush cache 


#######################################################################################
##
## udp limit
## 
##
########################################################################################
$IPT -A FORWARD -p udp --dport 53 -j ACCEPT
$IPT -A FORWARD -p udp --sport 53 -j ACCEPT
$IPT -A FORWARD -p udp -s 172.16.8.1/24 -j ACCEPT
$IPT -A FORWARD -p udp -d 172.16.8.1/24 -j ACCEPT
#$IPT -A FORWARD -p udp -j DROP

#######################################################################################
##
## CCI access gateway 22 port
##
#######################################################################################
$IPT -A INPUT -p tcp --dport 22  -j ACCEPT
$IPT -A OUTPUT -p tcp --sport 22 -j ACCEPT
$IPT -A INPUT -p udp --sport 123 -j ACCEPT
$IPT -A OUTPUT -p udp --dport 123 -j ACCEPT
$IPT -A FORWARD -p tcp --dport 22 -j ACCEPT
$IPT -A FORWARD -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT

# ICMP
$IPT -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
$IPT -A FORWARD -p icmp  -j ACCEPT

#######################################################################################
##
## CCI access gateway 25,110 port
##
#######################################################################################
$IPT -A FORWARD -p tcp --dport 25 -j ACCEPT
$IPT -A FORWARD -p tcp --sport 25 -j ACCEPT
$IPT -A FORWARD -p tcp --dport 110 -j ACCEPT
$IPT -A FORWARD -p tcp --sport 110 -j ACCEPT
$IPT -A FORWARD -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT

#######################################################################################
##
## Lduan ports: 7002
## YanHX: 7709,7711
## Zhangxiaowei:9999,8099,81 
##
########################################################################################
$IPT -A FORWARD -p tcp --dport 7002 -j ACCEPT
$IPT -A FORWARD -p tcp --dport 7709 -j ACCEPT
$IPT -A FORWARD -p tcp --dport 7711 -j ACCEPT
$IPT -A FORWARD -p tcp --dport 9999 -j ACCEPT
$IPT -A FORWARD -p tcp --dport 8099 -j ACCEPT
$IPT -A FORWARD -p tcp --dport 8080 -j ACCEPT
$IPT -A FORWARD -p tcp --dport 56580 -j ACCEPT
$IPT -A FORWARD -p tcp --dport 843 -j ACCEPT
$IPT -A FORWARD -p tcp --dport 1863 -j ACCEPT

#######################################################################################
#
# Openvpn
#
#######################################################################################
$IPT -A FORWARD -p tcp -i tap0 -j ACCEPT
$IPT -A FORWARD -p tcp -o tap0 -j ACCEPT

#########################################################################################
##
##  Drop for some black IPs
##      Control file: /etc/firewall/black[ip|port]
#########################################################################################
#$IPT -A OUTPUT -s 10.1.1.133 -m limit --limit 5/s --limit-burst 5 -j LOG --log-prefix "Drop packet" --log-level 4
#$IPT -A OUTPUT -s 10.1.1.133 -j DROP 
#for black in ` cat /etc/firewall/blackip|grep -v "^#" |grep "^[1-9]"`
#do
#	$IPT -A FORWARD -s $black -m limit --limit 30/s --limit-burst 20 -j LOG --log-prefix "Drop packet" --log-level 4
#	$IPT -A FORWARD -s $black -m limit --limit 30/s --limit-burst 20 -j ACCEPT
#	$IPT -A FORWARD -s $black -j DROP
#	$IPT -A FORWARD -d $black -m limit --limit 30/s --limit-burst 20 -j LOG --log-prefix "Drop packet" --log-level 4
#	$IPT -A FORWARD -d $black -m limit --limit 30/s --limit-burst 20 -j ACCEPT
#	$IPT -A FORWARD -d $black -j DROP
#done
for black in ` cat /etc/firewall/blackip|grep -v "^#" |grep "^[1-9]"`
do
        $IPT -A FORWARD -s $black -j DROP
done

#########################################################################################
# Map gateway:80 to mail.jfsys.com
#########################################################################################
$IPT -t nat -A PREROUTING -p tcp -i eth2 -d 124.207.105.226 --dport 80 -j DNAT --to-destination 220.231.38.200 
$IPT -t nat -A POSTROUTING -p tcp -s 220.231.38.200  --sport 80 -j SNAT --to-source 124.207.105.226
$IPT -A INPUT -p tcp --dport 80 -j ACCEPT
$IPT -A OUTPUT -p tcp --sport 80 -j ACCEPT


#########################################################################################
##
##    Nat ftp 192.168.2.253 
#########################################################################################
$IPT -t nat -A POSTROUTING -p tcp -s 192.168.2.253 --sport 21 -j SNAT --to-source 220.231.38.194 
$IPT -t nat -A PREROUTING  -p tcp -i eth0 -d 220.231.38.194 --dport 21 -j DNAT --to-destination 192.168.2.253:21
$IPT -t nat -A POSTROUTING -p tcp -s 192.168.2.253 --sport 65400:65410 -j SNAT --to-source 220.231.38.194 
$IPT -t nat -A PREROUTING -p tcp -i eth0 -d 220.231.38.194 --dport 65400:65410 -j DNAT --to-dest 192.168.2.253
$IPT -A INPUT -p tcp -d 220.231.38.194 --dport 21 -j ACCEPT
$IPT -A INPUT -p tcp -d 220.231.38.194 --dport 65400:65410 -j ACCEPT
$IPT -A OUTPUT -p tcp --sport 21 -j ACCEPT
$IPT -A OUTPUT -p tcp --sport 65400:65410 -j ACCEPT
#SMTPS
$IPT -A FORWARD -p tcp -d 124.207.105.228 --dport 465 -j ACCEPT
$IPT -A FORWARD -p tcp -d 220.231.38.195 --dport 465 -j ACCEPT
$IPT -A FORWARD -p tcp -s 124.207.105.228 --sport 465 -j ACCEPT
$IPT -A FORWARD -p tcp -s 220.231.38.195 --sport 465 -j ACCEPT

#NAT
jfnat()
{
  $IPT -t nat -A POSTROUTING -p $protocol -s $lanip --sport $lanport -j SNAT --to-source $wanip
  $IPT -t nat -A PREROUTING -p $protocol -d $wanip --dport $wanport -j DNAT --to-destination $lanip:$lanport
}
cat /etc/firewall/nat | grep -v "^#" | grep "^[1-9]" | while read natline
do
  lanip=`echo $natline | cut -d: -f1`
  lanport=`echo $natline | cut -d: -f2`
  wanip=`echo $natline | cut -d: -f3`
  wanport=`echo $natline | cut -d: -f4`
  protocol=`echo $natline | cut -d: -f5`
  jfnat
done

#########################################################################################
##
##  Allow MS remote desktop from Wan to JF-Lan
##      Control file: /etc/firewall/remotedesktop
#########################################################################################
cat /etc/firewall/remotedesktop|grep -v "^#" |grep "^[1-9]" | while read remoteD 
do
remoteport=`printf $remoteD|cut -d: -f2`
lanip=`printf $remoteD|cut -d: -f1`
$IPT -t nat -A POSTROUTING -p tcp -s $lanip --sport 3389  -j SNAT --to-source 220.231.38.194 
$IPT -t nat -A PREROUTING  -p tcp -i eth0 -d 220.231.38.194 --dport $remoteport -j DNAT --to-destination $lanip:3389
$IPT -t nat -A POSTROUTING -p tcp -s $lanip --sport 3389 -o eth2 -j SNAT --to-source 124.207.105.226
$IPT -t nat -A PREROUTING  -p tcp -i eth2 -d 124.207.105.226 --dport $remoteport -j DNAT --to-destination $lanip:3389

done

#########################################################################################
##
##  Allow VNC from Wan to JF-Lan
##      Control file: /etc/firewall/vncremoteports
#########################################################################################
cat /etc/firewall/vncremoteports|grep -v "^#" |grep "^[1-9]" | while read remoteD
do
remoteport=`printf $remoteD|cut -d: -f2`
lanip=`printf $remoteD|cut -d: -f1`
$IPT -t nat -A POSTROUTING -p tcp -s $lanip --sport 5900  -j SNAT --to-source 220.231.38.194 
$IPT -t nat -A PREROUTING  -p tcp -i eth0 -d 220.231.38.194 --dport $remoteport -j DNAT --to-destination $lanip:5900
$IPT -t nat -A POSTROUTING -p tcp -s $lanip --sport 5900 -o eth2 -j SNAT --to-source 124.207.105.226
$IPT -t nat -A PREROUTING  -p tcp -i eth2 -d 124.207.105.226 --dport $remoteport -j DNAT --to-destination $lanip:5900
done

#$IPT -t nat -A POSTROUTING -p tcp -s 10.1.1.130 --sport 5901  -j SNAT --to-source 220.231.38.194 
#$IPT -t nat -A PREROUTING  -p tcp -i eth0 -d 220.231.38.194 --dport 5901 -j DNAT --to-destination 10.1.1.130:5901

########################################################################################
##
## NewDepart 172.18.10.4 443
##
########################################################################################
$IPT -t nat -A POSTROUTING -p tcp -s 172.18.10.4 --sport 443 -o eth0 -j SNAT --to-source 220.231.38.194 
$IPT -t nat -A PREROUTING  -p tcp -i eth0 -d 220.231.38.194 --dport 443 -j DNAT --to-destination 172.18.10.4:443
$IPT -A FORWARD -p tcp -d 172.18.10.4 -j ACCEPT
$IPT -A FORWARD -p tcp -s 172.18.10.4 -j ACCEPT


#######################################################################################
##
##  MSA access wiki.jfsys.com.  192.168.2.17 nat 210.72.232.50
##
#######################################################################################
$IPT -A FORWARD -p tcp -s 220.194.21.15 -d 192.168.2.17 -j ACCEPT
$IPT -A FORWARD -p tcp -s 220.194.21.16 -d 192.168.2.17 -j ACCEPT
$IPT -A FORWARD -p tcp -s 220.194.21.49 -d 192.168.2.17 -j ACCEPT
$IPT -A FORWARD -p tcp -d 192.168.2.17 -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -p tcp -d 192.168.2.17 -j DROP

#######################################################################################
##
##  No limit IPs
##
#######################################################################################
$IPT -A FORWARD -p 47 -m state --state NEW -j ACCEPT
for superip in `cat /etc/firewall/superip|grep -v "^#" |grep "^[1-9]"`
do
        $IPT -A INPUT -s $superip -d $superip -j ACCEPT
	$IPT -A OUTPUT -s $superip -d $superip -j ACCEPT
        $IPT -A FORWARD -s $superip -j ACCEPT
        $IPT -A FORWARD -d $superip -j ACCEPT 
        $IPT -A FORWARD -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT
        $IPT -A FORWARD -p udp -m state --state ESTABLISHED,RELATED -j ACCEPT
        $IPT -A FORWARD -p 47  -m state --state ESTABLISHED,RELATED -j ACCEPT
done

for superport in `cat /etc/firewall/superport|grep -v "^#" |grep "^[1-9]"`
do
        $IPT -A FORWARD -p tcp  --dport $superport -j ACCEPT
        $IPT -A FORWARD -p udp  --dport $superport -j ACCEPT
        $IPT -A FORWARD -p 47  -m state --state ESTABLISHED,RELATED -j ACCEPT
done



#########################################################################################
##
##  Drop for some black IPs
##      Control file: /etc/firewall/black[ip|port]
#########################################################################################

for port in ` cat /etc/firewall/blackport|grep -v "^#" |grep "^[1-9]"`
do
        $IPT -A FORWARD -p tcp --dport $port -j DROP
        $IPT -A FORWARD -p udp --dport $port -j DROP
        $IPT -A FORWARD -p tcp --sport $port -j DROP
        $IPT -A FORWARD -p udp --sport $port -j DROP
done


######################################################################################
# PCTS VPN Box
#######################################################################################
$IPT -A FORWARD -s 172.16.2.1/24 -d 10.0.4.0/24 -j ACCEPT
$IPT -A FORWARD -s 10.0.4.0/24 -d 172.16.2.1/24 -j ACCEPT

######################################################################################
# cai VPN Box
#######################################################################################
$IPT -A FORWARD -s 172.18.10.1/24 -d 192.168.0.0/24 -j ACCEPT
$IPT -A FORWARD -s 192.168.0.0/24 -d 172.18.10.1/24 -j ACCEPT

#######################################################################################
# Mail server
#######################################################################################
$IPT -A FORWARD -s 202.205.9.171 -j ACCEPT
$IPT -A FORWARD -d 202.205.9.171 -j ACCEPT
$IPT -A FORWARD -p tcp -s 172.16.0.0/16   -m multiport --dport 110,25 -j ACCEPT
$IPT -A FORWARD -p udp -s 172.16.0.0/16   -m multiport --dport 110,25 -j ACCEPT

######################################################################################
# Allow DuanLi Group to access Duanzj Group
######################################################################################
$IPT -A FORWARD -s 172.16.6.1/24 -d 172.16.1.1/24 -j ACCEPT

#########################################################################################
##
## For CMCSC; FGZX and ZKZX
##
#########################################################################################
$IPT -A FORWARD -p tcp -s 172.32.16.1/24 -m multiport --dport 1723,80,110,21,20,22,25,53,443,9000 -j ACCEPT
$IPT -A FORWARD -p udp -s 172.32.16.1/24 -m multiport --dport 8000,9000 -j ACCEPT
$IPT -A FORWARD -p tcp -s 172.32.17.1/24 -m multiport --dport 1723,80,110,21,20,22,25,53,443 -j ACCEPT

#########################################################################################
##
##  For MSA subnet: special IPs NAT
## 
#########################################################################################
# Nat PCTS coolzilla services to a Wan IP(Use ZhangXG's Wan NAT IP)
$IPT -t nat -A POSTROUTING -p tcp -s 192.168.2.17 --sport 80    -j SNAT --to-source 210.72.232.34:80
$IPT -t nat -A PREROUTING  -p tcp -i eth0 -d 210.72.232.34 --dport 80 -j DNAT --to-destination 192.168.2.17:80

#########################################################################################
##
##  For Lancelot subnet: special IPs NAT
## 
#########################################################################################
# Nat PCTS coolzilla services to a Wan IP(Use ZhangXG's Wan NAT IP)
#$IPT -t nat -A POSTROUTING -p tcp -s 172.16.2.3 --sport 443    -j SNAT --to-source 211.154.5.15:443
#$IPT -t nat -A PREROUTING  -p tcp -i eth0 -d 211.154.5.15 --dport 443 -j DNAT --to-destination 172.16.2.3:443
$IPT -A FORWARD -p tcp -s 65.223.51.70/24 -d 172.16.2.3 --dport 443 -j ACCEPT
$IPT -A FORWARD -p tcp -s 65.223.51.70/24 -d 172.16.2.3 --dport 443 -m state --state ESTABLISHED,RELATED -j ACCEPT
#$IPT -A FORWARD -p tcp -s 65.223.51.65 -d 172.16.2.3 --dport 443 -j ACCEPT
#$IPT -A FORWARD -p tcp -s 65.223.51.65 -d 172.16.2.3 --dport 443 -m state --state ESTABLISHED,RELATED -j ACCEPT
# Zhang XiaoGen
#$IPT -t nat -A POSTROUTING -s 172.16.2.2   -j SNAT --to-source 119.255.17.118
#$IPT -t nat -A PREROUTING  -i eth0 -d 119.255.17.118 -j DNAT --to-destination 172.16.2.2
$IPT -A FORWARD -p tcp -d 172.16.2.2 -j ACCEPT
$IPT -A FORWARD -p udp -d 172.16.2.2 -j ACCEPT
$IPT -A FORWARD -p tcp -d 172.16.2.2 -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -p udp -d 172.16.2.2 -m state --state ESTABLISHED,RELATED -j ACCEPT
#$IPT -A FORWARD -d  172.16.2.2 -j ACCEPT
#$IPT -A FORWARD -d  172.16.2.2 -j ACCEPT
#$IPT -A FORWARD -s  172.16.2.2 -j ACCEPT
#$IPT -t nat -A POSTROUTING -s 172.16.2.16    -j SNAT --to-source 211.154.5.16
#$IPT -t nat -A PREROUTING  -i eth0 -d 211.154.5.16  -j DNAT --to-destination 172.16.2.16

#$IPT -t nat -A POSTROUTING -s 172.16.2.11    -j SNAT --to-source 202.205.9.169
#$IPT -t nat -A PREROUTING  -i eth0 -d 202.205.9.169  -j DNAT --to-destination 172.16.2.11

#$IPT -t nat -A POSTROUTING -s 172.16.2.9    -j SNAT --to-source 211.154.5.18
#$IPT -t nat -A PREROUTING  -i eth0 -d 211.154.5.18  -j DNAT --to-destination 172.16.2.9

#$IPT -t nat -A POSTROUTING -s 10.1.1.22   -j SNAT --to-source 218.107.142.213 
#$IPT -t nat -A PREROUTING  -i eth0 -d 218.107.142.213  -j DNAT --to-destination 10.1.1.22 

#$IPT -t nat -A POSTROUTING -s 10.1.1.17 -j SNAT --to-source 119.255.17.121 
#$IPT -t nat -A PREROUTING  -i eth0 -d 119.255.17.121 -j DNAT --to-destination 10.1.1.17
#$IPT -A FORWARD -p tcp -d 10.1.1.17 -j ACCEPT
#$IPT -A FORWARD -p udp -d 10.1.1.17 -j ACCEPT
#$IPT -A FORWARD -p tcp -d 10.1.1.17 -m state --state ESTABLISHED,RELATED -j ACCEPT
#$IPT -A FORWARD -p udp -d 10.1.1.17 -m state --state ESTABLISHED,RELATED -j ACCEPT

#$IPT -t nat -A POSTROUTING -p tcp -s 192.168.2.10 --sport 80 -j SNAT --to-source 119.255.17.123
#$IPT -t nat -A PREROUTING -p tcp -d 119.255.17.123 --dport 80 -j DNAT --to-destination 192.168.2.10:80
#$IPT -A INPUT -p tcp -d 119.255.17.123 --dport 80 -j ACCEPT
#$IPT -A OUTPUT -p tcp --sport 80 -j ACCEPT

# NAT JianFeng OA(192.168.2.11) For CCI access
$IPT -t nat -A POSTROUTING -s 192.168.2.11 -d 10.224.1.1/16   -j SNAT --to-source 10.1.1.66 
$IPT -t nat -A PREROUTING  -i eth0 -d 10.1.1.66 -s 10.224.1.1/16 -j DNAT --to-destination 192.168.2.11
$IPT -A FORWARD -d 192.168.2.11 -j ACCEPT
$IPT -A FORWARD -s 192.168.2.11 -j ACCEPT

##########################################################################
#
# Nat MASQUERADE : Lans --> Wan :Lans --> DMZ
# Wan access for all Lan_subs
#
###########################################################################
# For Lan address to Wan
$IPT -t nat -A POSTROUTING -o eth0  -j MASQUERADE
$IPT -t nat -A POSTROUTING -o eth2  -j MASQUERADE 

# For Lan address to DMZ 
$IPT -t nat -A POSTROUTING -o eth1 -s 10.1.1.1/16   -d 192.168.1.1/24  -j MASQUERADE 
$IPT -t nat -A POSTROUTING -o eth1 -s 172.16.1.1/24 -d 192.168.1.1/24  -j MASQUERADE
$IPT -t nat -A POSTROUTING -o eth1 -s 172.16.2.1/24 -d 192.168.1.1/24  -j MASQUERADE
$IPT -t nat -A POSTROUTING -o eth1 -s 172.16.6.1/24 -d 192.168.1.1/24  -j MASQUERADE
$IPT -t nat -A POSTROUTING -o eth1 -s 172.16.8.1/24 -d 192.168.1.1/24  -j MASQUERADE
$IPT -t nat -A POSTROUTING -o eth1 -s 172.18.10.1/24 -d 192.168.1.1/24  -j MASQUERADE
$IPT -t nat -A POSTROUTING -o eth1 -s 172.16.16.1/24 -d 192.168.1.1/24  -j MASQUERADE
$IPT -t nat -A POSTROUTING -o eth1 -s 172.16.9.1/24 -d 192.168.1.1/24  -j MASQUERADE
$IPT -t nat -A POSTROUTING -o eth1 -s 172.16.10.1/24 -d 192.168.1.1/24  -j MASQUERADE
$IPT -t nat -A POSTROUTING -o eth1 -s 172.16.11.1/24 -d 192.168.1.1/24  -j MASQUERADE
$IPT -t nat -A POSTROUTING -o eth1 -s 10.1.1.133 -d 172.16.1.20  -j MASQUERADE
#du.li access bugzilla.jfsys.cn
$IPT -t nat -A POSTROUTING -o eth1 -s 172.16.6.116 -d 172.16.1.20  -j MASQUERADE
#debug
#iptables -A FORWARD -p tcp --syn -s 172.16.2.5 -j TCPMSS --set-mss  1380 

############################################################################
# For some special rules about cci subnet CHINA <--> USA VPN
# Allow 10.1.1.255 to 10.225.20.255
############################################################################
/sbin/iptables -A FORWARD -p tcp -s 10.1.1.1/16 -d 10.224.20.4/22 -j ACCEPT
/sbin/iptables -A FORWARD -p tcp -s 10.224.20.4/22 -d 10.1.1.1/16 -j ACCEPT
/sbin/iptables -A FORWARD -p tcp -s 10.1.1.1/16 -d 10.224.20.4/22 -m state --state ESTABLISHED,RELATED -j ACCEPT
/sbin/iptables -A FORWARD -p tcp -s 10.224.20.4/22 -d 10.1.1.1/16 -m state --state ESTABLISHED,RELATED -j ACCEPT

############################################################################
# For icmp, uncomment only for debug
#############################################################################
#iptables -A FORWARD -p icmp -j ACCEPT
#iptables -A FORWARD -p icmp -m state --state ESTABLISHED,RELATED -j ACCEPT
#iptables -A INPUT  -p icmp -j ACCEPT
#
# The rules allow the icmp from localhost to Wan
#
/sbin/iptables -A OUTPUT -p icmp -j ACCEPT
/sbin/iptables -A INPUT -p icmp -m state --state ESTABLISHED,RELATED -j ACCEPT
#
# The rules allow the icmp from cmc_gw to localhost
#
/sbin/iptables -A INPUT -p icmp -s 219.238.133.3 -j ACCEPT
/sbin/iptables -A OUTPUT -p icmp -m state --state ESTABLISHED,RELATED -j ACCEPT

#############################################################################
# Rules For local ssh services from Wan
# For Gateway , only allow 218.107.142.181/28  219.238.133.1/27 to access local ssh server.
###############################################################################
/sbin/iptables -A INPUT  -i eth0 -s 10.1.1.1/16 -p tcp --dport 22 -j ACCEPT
/sbin/iptables -A INPUT  -i eth0 -s 10.1.1.1/16 -p tcp --sport 22 -j ACCEPT
/sbin/iptables -A OUTPUT  -d 10.1.1.1/16 -p tcp --dport 22 -j ACCEPT
/sbin/iptables -A OUTPUT  -d 10.1.1.1/16 -p tcp --sport 22 -j ACCEPT
/sbin/iptables -A INPUT  -i eth1 -s 10.1.1.1/16 -p tcp --dport 22 -j ACCEPT
/sbin/iptables -A INPUT  -i eth1 -s 10.1.1.1/16 -p tcp --sport 22 -j ACCEPT
/sbin/iptables -A OUTPUT -o eth1 -d 10.1.1.1/16 -p tcp --dport 22 -j ACCEPT
/sbin/iptables -A OUTPUT -o eth1 -d 10.1.1.1/16 -p tcp --sport 22 -j ACCEPT
/sbin/iptables -A INPUT  -i eth0 -p tcp --dport 22 -j ACCEPT
/sbin/iptables -A INPUT  -i eth0 -p tcp --sport 22 -j ACCEPT
/sbin/iptables -A OUTPUT  -p tcp --dport 22 -j ACCEPT
/sbin/iptables -A OUTPUT  -p tcp --sport 22 -j ACCEPT
/sbin/iptables -A INPUT  -i eth0 -p tcp --dport 22 -j ACCEPT
/sbin/iptables -A INPUT  -i eth0 -p tcp --sport 22 -j ACCEPT
/sbin/iptables -A OUTPUT  -p tcp --dport 22 -j ACCEPT
/sbin/iptables -A OUTPUT  -p tcp --sport 22 -j ACCEPT
/sbin/iptables -A OUTPUT -s 220.231.38.194 -j ACCEPT
/sbin/iptables -A INPUT  -s 220.231.38.194 -m state --state ESTABLISHED,RELATED -j ACCEPT

################################################################################
# Some deny rules for MS virus
################################################################################
$IPT -A FORWARD -p tcp -m multiport  --dport 135,445,6667 -j DROP
$IPT -A FORWARD -p udp -m multiport  --dport 135,445,6667 -j DROP
$IPT -A FORWARD -p tcp  --dport ircd -j DROP
$IPT -A FORWARD -p udp  --dport ircd -j DROP
$IPT -A INPUT -p tcp    --dport ircd -j DROP
$IPT -A INPUT -p udp    --dport ircd -j DROP

################################################################################
# For common DNS 
################################################################################
$IPT -A OUTPUT -p udp --dport 53 -j ACCEPT
$IPT -A OUTPUT -p tcp --dport 53 -j ACCEPT
$IPT -A OUTPUT -p udp --sport 53 -j ACCEPT
$IPT -A OUTPUT -p tcp --sport 53 -j ACCEPT
$IPT -A OUTPUT -p tcp --dport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -p tcp --sport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A INPUT -p tcp --sport 53 -j ACCEPT
$IPT -A INPUT -p udp --sport 53 -j ACCEPT
$IPT -A INPUT -p tcp --dport 53 -j ACCEPT
$IPT -A INPUT -p udp --dport 53 -j ACCEPT
$IPT -A INPUT -p tcp --sport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A INPUT -p tcp --dport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -p udp --dport 53 -j ACCEPT
$IPT -A FORWARD -p udp --dport 53 -j ACCEPT
$IPT -A FORWARD -p tcp --dport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -p udp --dport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -p udp --sport 53 -j ACCEPT
$IPT -A FORWARD -p udp --sport 53 -j ACCEPT
$IPT -A FORWARD -p tcp --sport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -p udp --sport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT

################################################################################
# Description: Some special IPs rules from cci subnet to other subnet
#	       Visit JF Lan from cci Lan.
#   IPs List: 	
#	10.1.1.124 For Fan Jiao 
#	10.1.1.123 For Qian Feng
# 	10.1.1.132 For Leng Wei
#	10.1.1.189 For Liu Zhong
#       172.16.2.10 For Zhang XiaoGen
#	172.16.2.3 For Gate ssh access
################################################################################
special_admin(){
for ips in `cat /etc/special_ips_admin |grep -v "^#" |grep "^[1-9]"`
do
        # Access Wan( No limited)
        $IPT -A FORWARD -p tcp  -s $ips/32  -j ACCEPT
        $IPT -A FORWARD -p udp  -s $ips/32  -j ACCEPT
        $IPT -A FORWARD -p tcp  -s $ips/32  -j ACCEPT
        $IPT -A FORWARD -p udp  -s $ips/32  -j ACCEPT
	# visit JianFeng WAN
	$IPT -A FORWARD -p tcp -s $ips/32 -d 220.231.38.200/28 -j ACCEPT
	$IPT -A FORWARD -p tcp -s $ips/32 -d 220.231.38.200/28 -m state --state ESTABLISHED,RELATED -j ACCEPT
	# visit JianFeng internal subnet
	$IPT -A FORWARD -p tcp -s $ips/32 -d 172.16.1.1/24 -j ACCEPT
	$IPT -A FORWARD -p tcp -s $ips/32 -d 172.16.1.1/24 -m state --state ESTABLISHED,RELATED -j ACCEPT
        # visit CAI subnet
        $IPT -A FORWARD -p tcp -s $ips/32 -d 172.18.10.1/24 -j ACCEPT
        $IPT -A FORWARD -p tcp -s $ips/32 -d 172.18.10.1/24 -m state --state ESTABLISHED,RELATED -j ACCEPT
	# visit JF Lancelot subnet
	$IPT -A FORWARD -p tcp -s $ips/32 -d 172.16.2.1/24 -j ACCEPT
        $IPT -A FORWARD -p tcp -s $ips/32 -d 172.16.2.1/24 -m state --state ESTABLISHED,RELATED -j ACCEPT
	# visit DMZ subnet
	$IPT -A FORWARD -p tcp -s $ips/32 -d 192.168.1.1/24 -j ACCEPT
        $IPT -A FORWARD -p tcp -s $ips/32 -d 192.168.1.1/24 -m state --state ESTABLISHED,RELATED -j ACCEPT
        $IPT -A FORWARD -p tcp -s $ips/32 -d 192.168.2.1/24 -j ACCEPT
        $IPT -A FORWARD -p tcp -s $ips/32 -d 192.168.2.1/24 -m state --state ESTABLISHED,RELATED -j ACCEPT
done
# For DuanZJ group access YingHang host in DMZ
for ips in `cat /etc/firewall/guonei_list |grep -v "^#" |grep "^[1-9]"`
do      
       $IPT -A FORWARD -p tcp -s $ips/32 -d 192.168.1.22/32 -j ACCEPT
done

# For Zheng XiaoGeng access Lancelot subnet and China_internal_subnet
#$IPT -A FORWARD -p tcp -s 172.16.2.10 -d 172.16.1.1/24 -j ACCEPT
#$IPT -A FORWARD -p tcp -s 172.16.2.10 -d 172.16.1.1/24 -m state --state ESTABLISHED,RELATED -j ACCEPT

# For Gateway access 172.16.2.3
#$IPT -A OUTPUT -p tcp -s 172.16.2.1 -d 172.16.2.3 --dport 22 -j ACCEPT
#$IPT -A INPUT -p tcp  -s 172.16.2.3 -d 172.16.2.1 --sport 22  -m state --state ESTABLISHED,RELATED -j ACCEPT
}

##############################################################################################
# For JianFeng common IT resources which are in cci subnet 
# Allow JianFeng China subnet to access file server and printer server in JianFeng cci subnet
#       10.1.1.9        file server
#       192.168.2.208      printer server
#       10.1.1.13	info.jfsys.com
#   
#       172.16.6.1      JianFeng administrations
#       172.18.10.1     CAI
#       172.16.8.1      PD
#       172.16.2.1      PCTS
#       172.16.1.1      Duan project group
#       10.1.1.1        CCI
# 
#    /etc/unlimited_jf  For DuanZJ group
#    /etc/unlimited_Lancelot For PCTS group
#    
##############################################################################################
jf_china_spec(){
    # For common IT Stuffs
    for ips in `cat /etc/net_IPs|grep -v "^#" |grep -v "^$"`
    do
      $IPT -A FORWARD -p udp -s $ips -d 10.1.1.9 -m multiport --dport 53,139,445,1300 -j ACCEPT
      $IPT -A FORWARD -p tcp -s $ips -d 10.1.1.9 -m multiport --dport 53,139,445,1300 -j ACCEPT
      $IPT -A FORWARD -p all -s $ips -d 10.1.1.9 -m state --state ESTABLISHED,RELATED -j ACCEPT
      $IPT -A FORWARD -p all -s $ips -d 10.1.1.208 -j ACCEPT
      $IPT -A FORWARD -p all -s $ips -d 10.1.1.208 -m state --state ESTABLISHED,RELATED -j ACCEPT
      #$IPT -A FORWARD -p tcp -s $ips -d 10.1.1.13 --dport 80 -j ACCEPT
      #$IPT -A FORWARD -p tcp -s $ips -d 10.1.1.13 --dport 80 -m state --state ESTABLISHED,RELATED -j ACCEPT
    done
}

################################################################################
# For 10.3.1.1. There are two host for visit www. The opened ports is 80, 8080, 21, 22
#   5999 port: Qian request
#   2401 port: cvs
#   63.251.123.12: cci eng7 host
#   119/tcp 119/udp: readnews untp nntp
#   gmail: 995 465
#   MS E_learning: tcp:1755,554 udp:1755
################################################################################
net_priv(){
    # For ccieng privilage users
    $IPT -A FORWARD -p all -m state --state ESTABLISHED,RELATED -j ACCEPT

    for ulport in `cat /etc/unlimited_port |grep -v "#"`
    do
     $IPT -A FORWARD -p tcp -m multiport --dport $ulport -j ACCEPT
    done

    # For CCI group
      $IPT -A FORWARD -d 63.251.123.1/24 -j ACCEPT
   for ips in `cat /etc/firewall/cci_list|grep -v "^#" |grep -v "^$"`
    do
      $IPT -A FORWARD -p udp -s $ips   -m multiport --dport 2401,1723,21,20,22 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips   -m multiport --dport 2401,1723,21,20,22 -j ACCEPT
      $IPT -A FORWARD -p tcp -s $ips   -m multiport --dport 843,1863,8080,995,465,1755,554 -j ACCEPT
      $IPT -A FORWARD -p tcp -s $ips   -m multiport --dport 843,1863,123,873,995,465,554 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips   -m multiport --dport 123,873,995,465 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips   -m multiport --dport 123,873,995,465 -j ACCEPT
    done

    # For GuoNei group 
  for ips in `cat /etc/firewall/guonei_list|grep -v "^#" |grep -v "^$"`
    do
      $IPT -A FORWARD -p tcp -s $ips -m multiport --dport 8080,21,20,22,25,53,443 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips -m multiport --dport 8080,21,20,25,53,443 -j ACCEPT
      $IPT -A FORWARD -p tcp -s $ips -m multiport --dport 8080,21,20,22,25,53,443 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips -m multiport --dport 8080,21,20,25,53,443 -j ACCEPT
    done

    # For JF Lancelot Project Group
    #for ips in `cat /etc/unlimited_Lancelot`
    #do
      #$IPT -A FORWARD -p tcp -s $ips/32  -m multiport --dport 1723,3389,80,110,21,20,22,25,53,8080,443 -j ACCEPT
      #$IPT -A FORWARD -p udp -s $ips/32  -m multiport --dport 1723,3389,80,110,21,20,22,25,53,8080,443 -j ACCEPT
      $IPT -A FORWARD -d 65.223.51.68/24 -j ACCEPT
  for ips in `cat /etc/firewall/pcts_list|grep -v "^#" |grep -v "^$"`
    do
      $IPT -A FORWARD -p tcp -s $ips -m multiport --dport 1723,21,20,22,25,53,443,8090 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips -m multiport --dport 1723,21,20,22,25,53,443,8090 -j ACCEPT
      $IPT -A FORWARD -p 47 -s $ips -m state --state NEW -j ACCEPT 
      $IPT -A FORWARD -p udp -s $ips -m multiport --dport 1723,21,20,22,25,53,443,8090 -j ACCEPT
      $IPT -A FORWARD -p tcp -s $ips -m multiport --dport 1723,21,20,22,25,53,443,8090 -j ACCEPT
    done


    # For Administration department: 7002 port for JiaoGuanJu
  for ips in `cat /etc/firewall/xingzheng_list|grep -v "^#" |grep -v "^$"`
    do
      $IPT -A FORWARD -p tcp -s $ips   -m multiport --dport 843,1863,1723,80,110,21,20,22,25,53,8080,443,8090,7002 -j ACCEPT
      $IPT -A FORWARD -p tcp -s $ips   -m multiport --dport 843,1863,1723,80,110,21,20,22,25,53,8080,443,8090,7002 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443,8090,7002 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443,8090,7002 -j ACCEPT
    done
    # For PD(England) Project Group
    $IPT -A FORWARD -i eth1  -d 217.23.171.195 -j ACCEPT
    $IPT -A FORWARD -i eth1  -d 217.23.171.215 -j ACCEPT
  for ips in `cat /etc/firewall/pd_list|grep -v "^#" |grep -v "^$"`
    do
      $IPT -A FORWARD -p tcp -s $ips   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
      $IPT -A FORWARD -p tcp -s $ips   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
    done
    # For QiHua subnet
  for ips in `cat /etc/firewall/qihua_list|grep -v "^#" |grep -v "^$"`
    do
      $IPT -A FORWARD -p tcp -s $ips  -m multiport --dport 8888,3389,1723,119,80,110,21,20,22,25,53,8080,443 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips  -m multiport --dport 8888,3389,1723,119,80,110,21,20,25,53,4568,4569,443 -j ACCEPT
      $IPT -A FORWARD -p tcp -s $ips  -m multiport --dport 8888,3389,1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips  -m multiport --dport 8888,3389,1723,80,110,21,20,25,53,4568,4569,443 -j ACCEPT

    done
    # For CaiWu subnet
  for ips in `cat /etc/firewall/caiwu_list|grep -v "^#" |grep -v "^$"`
    do
      $IPT -A FORWARD -p tcp -s $ips  -m multiport --dport 1723,80,110,21,20,22,25,53,443 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips  -m multiport --dport 1723,80,110,21,20,25,53,443 -j ACCEPT
      $IPT -A FORWARD -p tcp -s $ips  -m multiport --dport 1723,80,110,21,20,22,25,53,443 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips  -m multiport --dport 1723,80,110,21,20,25,53,443 -j ACCEPT
    done
    # For Market subnet
  for ips in `cat /etc/firewall/market_list|grep -v "^#" |grep -v "^$"`
    do
      for marketport in `cat /etc/firewall/market_port|grep -v "^#" |grep -v "^$"`
        do
	  $IPT -A FORWARD -p tcp -s $ips  -m multiport --dport $marketport -j ACCEPT
      	  $IPT -A FORWARD -p udp -s $ips  -m multiport --dport $marketport -j ACCEPT
          $IPT -A FORWARD -p tcp -s $ips  -m multiport --dport $marketport -j ACCEPT
          $IPT -A FORWARD -p udp -s $ips  -m multiport --dport $marketport -j ACCEPT
	done
    done
    # For HR subnet
  for ips in `cat /etc/firewall/hr_list|grep -v "^#" |grep -v "^$"`
    do
      $IPT -A FORWARD -p tcp -s $ips  -m multiport --dport 8888,3389,1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips  -m multiport --dport 8888,3389,1723,80,110,21,20,25,53,4568,4569,443 -j ACCEPT
      $IPT -A FORWARD -p tcp -s $ips  -m multiport --dport 8888,3389,1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips  -m multiport --dport 8888,3389,1723,80,110,21,20,25,53,4568,4569,443 -j ACCEPT
    done
    # For CAI(USA)  Project Group
  for ips in `cat /etc/firewall/cai_list|grep -v "^#" |grep -v "^$"`
    do
      $IPT -A FORWARD -p 47 -s $ips  -m state --state NEW -j ACCEPT
      $IPT -A FORWARD -p tcp -s $ips   -m multiport --dport 1723,80,110,21,20,22,25,53,443 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips   -m multiport --dport 1723,80,110,21,20,22,25,53,443 -j ACCEPT
      $IPT -A FORWARD -p 47 -s $ips  -m state --state NEW -j ACCEPT
      $IPT -A FORWARD -p tcp -s $ips   -m multiport --dport 1723,80,110,21,20,22,25,53,443 -j ACCEPT
      $IPT -A FORWARD -p udp -s $ips   -m multiport --dport 1723,80,110,21,20,22,25,53,443 -j ACCEPT
    done
    # For Yang De Si Te subnet
    $IPT -A FORWARD -p tcp -s 172.18.1.1/24   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
    $IPT -A FORWARD -p udp -s 172.18.1.1/24   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
    $IPT -A FORWARD -p tcp -s 172.18.1.1/24   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
    $IPT -A FORWARD -p udp -s 172.18.1.1/24   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT


    # For access common IT resources
    jf_china_spec
    

}

#
# For all users out of work time
#  3389 port: terminal server
#  1723 port: vpn service
#
net_all(){
	
        $IPT -A FORWARD -p all -m state --state ESTABLISHED,RELATED -j ACCEPT        

	# For cci subnet
     for ips in `cat /etc/firewall/cci_list|grep -v "^#" |grep -v "^$"`
       do
	$IPT -A FORWARD -p tcp -s $ips   -j ACCEPT
        $IPT -A FORWARD -p tcp -s $ips   -j ACCEPT
        $IPT -A FORWARD -p udp -s $ips   -j ACCEPT
       done
        # For Administration department
    for ips in `cat /etc/firewall/xingzheng_list|grep -v "^#" |grep -v "^$"`
      do
        $IPT -A FORWARD -p tcp -s $ips   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
        $IPT -A FORWARD -p udp -s $ips   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
      done
        # For PD(England) Project Group
    for ips in `cat /etc/firewall/pd_list|grep -v "^#" |grep -v "^$"`
      do
        $IPT -A FORWARD -p tcp -s $ips   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
        $IPT -A FORWARD -p udp -s $ips   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
        $IPT -A FORWARD -p tcp -s $ips   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
        $IPT -A FORWARD -p udp -s $ips   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
      done
        # For CAI(USA) Project Group
   for ips in `cat /etc/firewall/cai_list|grep -v "^#" |grep -v "^$"`
      do
        $IPT -A FORWARD -p tcp -s $ips  -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
        $IPT -A FORWARD -p udp -s $ips  -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
        $IPT -A FORWARD -p 47 -s $ips  -m state --state NEW -j ACCEPT
      done

        # For DuanZJ subnet
   for ips in `cat /etc/firewall/guonei_list|grep -v "^#" |grep -v "^$"`
      do
	$IPT -A FORWARD -p tcp -s $ips  -m multiport --dport 8888,3389,1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
        $IPT -A FORWARD -p udp -s $ips  -m multiport --dport 8888,3389,1723,80,110,21,20,25,53,4568,4569,443 -j ACCEPT
      done
        # For QiHua subnet
   for ips in `cat /etc/firewall/qihua_list|grep -v "^#" |grep -v "^$"`
      do
 	$IPT -A FORWARD -p tcp -s $ips  -m multiport --dport 8888,3389,1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
        $IPT -A FORWARD -p udp -s $ips  -m multiport --dport 8888,3389,1723,80,110,21,20,25,53,4568,4569,443 -j ACCEPT
      done
        # For CaiWu subnet
   for ips in `cat /etc/firewall/caiwu_list|grep -v "^#" |grep -v "^$"`
      do
        $IPT -A FORWARD -p tcp -s $ips  -m multiport --dport 8888,3389,1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
        $IPT -A FORWARD -p udp -s $ips  -m multiport --dport 8888,3389,1723,80,110,21,20,25,53,4568,4569,443 -j ACCEPT
      done
        # For Market subnet
   for ips in `cat /etc/firewall/market_list|grep -v "^#" |grep -v "^$"`
      do
        $IPT -A FORWARD -p tcp -s $ips  -m multiport --dport 8888,3389,1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
        $IPT -A FORWARD -p udp -s $ips  -m multiport --dport 8888,3389,1723,80,110,21,20,25,53,4568,4569,443 -j ACCEPT      
      done

        # For HR subnet
   for ips in `cat /etc/firewall/hr_list|grep -v "^#" |grep -v "^$"`
      do
        $IPT -A FORWARD -p tcp -s $ips  -m multiport --dport 8888,3389,1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
        $IPT -A FORWARD -p udp -s $ips  -m multiport --dport 8888,3389,1723,80,110,21,20,25,53,4568,4569,443 -j ACCEPT
      done

        # For JF Lancelot subnet
   for ips in `cat /etc/firewall/pcts_list|grep -v "^#" |grep -v "^$"`
      do
        $IPT -A FORWARD -p tcp -s $ips -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
        $IPT -A FORWARD -p udp -s $ips -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
        $IPT -A FORWARD -p tcp -s $ips -j ACCEPT
        $IPT -A FORWARD -p udp -s $ips -j ACCEPT
      $IPT -A FORWARD -p 47 -s 172.16.2.1/24  -m state --state NEW -j ACCEPT
     done
        $IPT -A FORWARD -d 65.223.51.68/24 -j ACCEPT

        # For Dang De Si Te
        $IPT -A FORWARD -p tcp -s 172.18.1.1/24   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT
        $IPT -A FORWARD -p udp -s 172.18.1.1/24   -m multiport --dport 1723,80,110,21,20,22,25,53,8080,443 -j ACCEPT

	# Rules for JianFeng IT resources	
	jf_china_spec


}

################################################################################
# DMZ Section:  
#	CMC YingHang NewWork: Wan_IP: 210.72.232.52 DMZ_IP: 192.168.1.22
#                      Ports: 80,8080,8000,22.143.25.110          
#       USA_JF_VPN(JF Lancelot): 211.154.5.14  DMZ_IP: 192.168.1.10 Sub_IP: 172.16.2.2  
#                         Ports: 1723,47(GRE protocal) 
#                       Sub_net: 172.16.2.1/24 eth4
#		        Gateway: 172.16.2.1
#       USA_CAI_VPN: 202.205.9.170 DMZ_IP: 192.168.1.40 Sub_IP: 272.18.10.3
#             Ports: 1723,47(GRE protocal)
#           Sub_net: 172.18.10.3/24
#           Gateway: 172.18.10.1
#       JianFeng Common Servers: 192.168.2.10/11
#
#                                         
################################################################################

####################################### For YingHang NetWork web server #######################################
#
# for ext service for www server || nat
#
#$IPT -t nat -A POSTROUTING -s 192.168.1.22    -j SNAT --to-source 210.72.232.52
#$IPT -t nat -A PREROUTING  -d 210.72.232.52  -j DNAT --to-destination 192.168.1.22

#
# These hosts only access www and ssh 
#
$IPT -A FORWARD -p tcp -d 192.168.1.22  -m multiport --dport 80,8080,8000,22,143,25,110 -i eth0 -j ACCEPT
$IPT -A FORWARD -p tcp -d 192.168.1.22  -i eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -p tcp -d 192.168.1.22  -m multiport --dport 80,8080,8000,22,143,25,110 -o eth1 -j ACCEPT
$IPT -A FORWARD -p tcp -d 192.168.1.22  -o eth1 -m state --state ESTABLISHED,RELATED -j ACCEPT

$IPT -A FORWARD -p ALL -s 192.168.1.22  -j ACCEPT
$IPT -A FORWARD -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT

###################################
#bugzilla for jfcn
###################################

$IPT -t nat -A POSTROUTING -s 172.16.1.20    -j SNAT --to-source 210.72.232.34
$IPT -t nat -A PREROUTING  -d 210.72.232.34  -j DNAT --to-destination 172.16.1.20
$IPT -A FORWARD -d 210.72.232.34 -j ACCEPT
$IPT -A FORWARD -p tcp -s 219.238.133.3 -d 172.16.1.20  -m multiport --dport 80 -i eth0 -j ACCEPT
$IPT -A FORWARD -p tcp -s 219.238.133.3 -d 172.16.1.20  -i eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -p tcp -d 172.16.1.20  -m multiport --dport 80 -i eth1 -j ACCEPT
$IPT -A FORWARD -p tcp -d 172.16.1.20  -o eth1 -m state --state ESTABLISHED,RELATED -j ACCEPT


$IPT -A FORWARD -p ALL -s 172.16.1.20  -j ACCEPT
$IPT -A FORWARD -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT


########################## For CAI VPN ######################################################
#
# For CAI VPN Server ext service for NAT
#
#$IPT -t nat -A POSTROUTING -s 192.168.1.40    -j SNAT --to-source 202.205.9.170
#$IPT -t nat -A PREROUTING  -i eth0 -d 202.205.9.170  -j DNAT --to-destination 192.168.1.40
#
# For CAI  lan service for nat
#
#$IPT -t nat -A POSTROUTING -s 192.168.1.40   -j SNAT --to-source 172.18.10.1
#$IPT -t nat -A PREROUTING  -i eth0 -d 202.205.9.170 -j DNAT --to-destination 192.168.1.40

#$IPT -t nat -A POSTROUTING -s 192.168.1.40   -j SNAT --to-source 10.1.1.3
#$IPT -t nat -A PREROUTING  -i eth0 -d 202.205.9.170 -j DNAT --to-destination 192.168.1.40

#
# For Windows vpn server 
#
$IPT -A FORWARD -p 47  -d 192.168.1.40 -i eth0 -m state --state NEW -j ACCEPT
$IPT -A FORWARD -p tcp -d 192.168.1.40 -i eth0 --dport 1723  -m state --state NEW -j ACCEPT
$IPT -A FORWARD -p 47  -d 192.168.1.40 -i eth0 -m state --state NEW -j ACCEPT
$IPT -A FORWARD -p tcp -d 192.168.1.40 -i eth0 --dport 1723  -m state --state NEW -j ACCEPT

########################## For JF Lancelot VPN ######################################################
#
# for JF Lancelot VPN Server ext service for nat
#
#$IPT -t nat -A POSTROUTING -s 192.168.1.10    -j SNAT --to-source 211.154.5.14
#$IPT -t nat -A PREROUTING  -i eth0 -d 211.154.5.14  -j DNAT --to-destination 192.168.1.10
#
# for JF Lancelot lan service for nat
#
#$IPT -t nat -A POSTROUTING -s 192.168.1.10  -o eth1 -j SNAT --to-source 172.16.2.1
#$IPT -t nat -A PREROUTING  -i eth1 -d 211.154.5.14 -j DNAT --to-destination 192.168.1.10

#
# For Windows vpn server 
#
$IPT -A FORWARD -p 47  -d 192.168.1.10 -i eth0 -m state --state NEW -j ACCEPT
$IPT -A FORWARD -p tcp -d 192.168.1.10 -i eth0 --dport 1723  -m state --state NEW -j ACCEPT

########################## For JianFeng Common Servers ######################################################
#
# For 192.168.2.10 Commsys1. This server only service for internal users
# For IBM Host. 192.168.2.11 work.jfsys.com weblog.jfsys.com KaoQing
# For OA 2 Host
$IPT -A FORWARD -p tcp -i eth1 -s 192.168.2.10/24 -j ACCEPT
$IPT -A FORWARD -p udp -i eth1 -s 192.168.2.10/24 -j ACCEPT
$IPT -A FORWARD -p tcp -o eth1 -d 192.168.2.10/24 -j ACCEPT
$IPT -A FORWARD -p udp -o eth1 -d 192.168.2.10/24 -j ACCEPT
$IPT -A FORWARD -p tcp -i eth1 -s 192.168.2.11/24 --dport 25 -j ACCEPT
$IPT -A FORWARD -p udp -i eth1 -s 192.168.2.11/24 --dport 25 -j ACCEPT
$IPT -A FORWARD -p tcp -i eth1 -s 192.168.2.11/24 --dport 25 -m state --state NEW -j ACCEPT
$IPT -A FORWARD -p udp -i eth1 -s 192.168.2.11/24 --dport 25 -m state --state NEW -j ACCEPT
# For commsys1 access GATE server
$IPT -A INPUT -p tcp --dport 22 -i eth1 -s 192.168.2.10/24 -j ACCEPT


# Nat 10.1.1.13 
$IPT -t nat -A POSTROUTING -s 10.1.1.13  -j SNAT --to-source 220.231.38.203
$IPT -t nat -A PREROUTING  -d 220.231.38.203 -j DNAT --to-destination 10.1.1.13
$IPT -A INPUT -s 220.231.38.203 -d 220.231.38.203 -j ACCEPT
$IPT -A OUTPUT -s 220.231.38.203 -d 220.231.38.203 -j ACCEPT
$IPT -A FORWARD -s 220.231.38.203 -p tcp --match multiport --dports 1024:65535 -j ACCEPT
$IPT -A FORWARD -d 220.231.38.203 -p tcp --match multiport --dports 1024:65535 -j ACCEPT
$IPT -A FORWARD -s 220.231.38.203 -p udp --match multiport --dports 1024:65535 -j ACCEPT
$IPT -A FORWARD -d 220.231.38.203 -p udp --match multiport --dports 1024:65535 -j ACCEPT
$IPT -A FORWARD -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -p udp -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -p 47  -m state --state ESTABLISHED,RELATED -j ACCEPT

#########################################################################################################
# OpenVpn : connect jf_gate with cmc_gate
#	    jf_gate: 218.107.142.181 10.8.0.2
#           cmc_gate:219.238.133.3 10.8.0.1
#           On Wan interface: only open 6000 port
#           On tun+ interface: only open tun+ for input, forward, and output. 
#                              only allow 10.3.1.254 to access jfnet 
#  Packages: openvpn, openssl, lzo(real-time data compression library)
#               Kernel:  tun.o module
#########################################################################################################
$IPT -A FORWARD -p udp --dport 5000 -j ACCEPT
$IPT -A FORWARD -p udp --dport 5000 -j ACCEPT
$IPT -A INPUT   -p udp --dport 5000 -j ACCEPT
$IPT -A OUTPUT  -p udp --dport 5000 -j ACCEPT
$IPT -A FORWARD  -p all  -i tap+ -j ACCEPT
$IPT -A FORWARD  -p all  -i tap+ -j ACCEPT
$IPT -A FORWARD  -p all -i tap+ -m state --state ESTABLISHED,RELATED -j ACCEPT 
$IPT -A FORWARD  -p all -o tap+ -j ACCEPT
$IPT -A INPUT -p all -i tap+ -j ACCEPT
$IPT -A INPUT -p all -i tap+ -j ACCEPT
$IPT -A OUTPUT -p all -o tap+ -j ACCEPT
#
# Allow Duanzj group access CMCSC
# jfgate:/etc/DuanVpnList
# cmcgate:/etc/JF_Admin_IPs
#
for ips in `cat /etc/DuanVpnList`
do
  $IPT -A FORWARD -s $ips -o tap+ -j ACCEPT
  $IPT -A FORWARD -s $ips -o tap+ -m state --state ESTABLISHED,RELATED -j ACCEPT
done

/sbin/ip rule del from 172.18.10.11 table eth2table
/sbin/ip rule add from 172.18.10.11 table eth2table

#/sbin/route add default gw 220.231.38.193

#ip route del default scope global
#ip route add default scope global nexthop via 220.231.38.193 dev eth0 weight 1 nexthop via 124.207.105.225 dev eth2 weight 1


#########################################################################################################
# Main routine
#########################################################################################################

case $1 in
deny)
special_admin
net_priv
;;
allow)
net_priv
;;
*)
net_priv
esac






