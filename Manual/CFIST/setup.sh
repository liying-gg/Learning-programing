#!/bin/sh

#Because the interface name should be determined after the system setup,
#we need the setup command run the the customer

#Check the usage and interface avalibility
if [ $# -ne 1 ]
then
    echo "Usage : $0 'ethernet card'"
    echo "    Eg: $0 'eth0'"
    exit 1
else
    ifconfig | grep -w $1 >/dev/null
    [ $? -ne 0 ]&&echo "No such interface"
fi

#Set up the net.ipv4.tcp_timestamps system option
sed -i 's/.*net.ipv4.tcp_timestamps.*//g' /etc/sysctl.conf
echo "net.ipv4.tcp_timestamps = 0" >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

#Heartbeat configuration
#To do

#sslgwWeb setup
mgmtip=`ifconfig $1|grep "inet addr"|awk -F "[:]" '{print $2}'|awk '{print $1}'`
sed -i "s/mgmtip/${mgmtip}/" /usr/local/SSLGW_WEB/tomcat/conf/server.xml

/usr/local/SSLGW_WEB/web/script/monitor/sslgw-rrd/sslgw_rrd_install.sh $1
/usr/local/SSLGW_WEB/web/script/monitor/self-check/self_check_install.sh
/usr/local/SSLGW_WEB/web/script/init.d/iptables.rules $1 /dev/null

chown cfist:cfist /usr/local/SSLGW_WEB/web/script/monitor/sslgw-rrd/sslgw-rrd.conf

sudo -u cfist service sslgwWeb restart

service iptables start
/sbin/iptables -A INPUT -i $1 -p tcp -m tcp --dport 1357 -j ACCEPT
/sbin/iptables -A INPUT -p tcp --dport 1357 -m state --state NEW -m recent --set --name ssh --rsource 
/sbin/iptables -A INPUT -p tcp --dport 1357 -m state --state NEW -m recent ! --rcheck --seconds 60 --hitcount 4 --name ssh --rsource -j ACCEPT
service iptables save
