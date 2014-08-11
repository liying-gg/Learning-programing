Name: sslgw_web
Summary: CFIST SSL GATEWAY WEB CONTROL
Version: vvv
Release: rrr
License: CFIST
Group: Development
Vendor: CFIST
Packager: CFIST <http://www.cfist.com.cn>
Distribution: linux
BuildRoot: %{_tmppath}/%{name}-root
AutoReqProv: no
Requires:shadow-utils
Requires:chkconfig
Requires:coreutils
Requires:sed
Requires:policycoreutils
Requires:sudo
Requires:pam
Requires:net-snmp
Requires:setup
Requires:heartbeat
Requires:cronie
Requires:initscripts
Requires:iptables
Requires:openssh-server

%define _buildshell /bin/bash

%description
CFIST SSL GATEWAY WEB CONTROL

%files
%attr(0755, cfist, cfist) /etc/init.d/sslgwWeb
%attr(0755, cfist, cfist) /etc/init.d/autorun
%attr(0755, cfist, cfist) /root/blacklist.conf
%attr(0755, cfist, cfist) /root/setup.sh
%attr(0755, cfist, cfist) /usr/local/SSLGW_WEB/
%attr(0755, cfist, cfist) /usr/bin/lsb_release

%pre
/usr/sbin/useradd -p "sKjauStP0jWfs" cfist

%post
/sbin/chkconfig --level 2345 autorun on
/sbin/chkconfig --level 2345 snmpd on
/bin/chown cfist:cfist /etc/snmp/snmpd.conf
/bin/chown cfist:cfist /etc/hosts
/bin/chown cfist:cfist /etc/sysconfig/network
/bin/chown -R cfist:cfist /etc/sysconfig/network-scripts/
/bin/chown -R cfist:cfist /etc/ha.d/
/bin/touch /var/spool/cron/cfist
/bin/chmod 644 /var/spool/cron/cfist
/bin/chown -R cfist:cfist /var/spool/cron/
/bin/echo "* soft nofile 204800" >>/etc/security/limits.conf
/bin/echo "* hard nofile 204800" >>/etc/security/limits.conf
/bin/touch /etc/modprobe.conf
/bin/touch /etc/ha.d/resource.d/ARP
/bin/cp -f /usr/local/SSLGW_WEB/web/script/build/ha.cf /etc/ha.d/
/bin/cp -f /usr/local/SSLGW_WEB/web/script/build/authkeys /etc/ha.d/
/bin/cp -f /usr/share/doc/heartbeat-3.0.4/haresources /etc/ha.d/
/bin/chmod 755 /etc/ha.d/resource.d/ARP
/bin/chmod 600 /etc/ha.d/authkeys
/bin/chown cfist:cfist /etc/ha.d/resource.d/ARP
/bin/chown cfist:cfist /etc/modprobe.conf
/bin/chown cfist:cfist /etc/rsyslog.conf
/bin/chown cfist:cfist /etc/ha.d/ha.cf
/bin/chown cfist:cfist /etc/ha.d/authkeys
/bin/chown cfist:cfist /etc/ha.d/haresources
/bin/sed -i 's@^ONBOOT=no@ONBOOT=yes@' /etc/sysconfig/network-scripts/ifcfg-*
/bin/sed -i 's@is not running@stopped@' /etc/init.d/iptables
/bin/sed -i "s@.*Defaults.*requiretty@#&@" /etc/sudoers
/bin/sed -i "s@CentOS.*@SSL GATEWAY vvv.rrr@" /etc/issue*
/bin/sed -i "s@#Port 22@Port 1357@" /etc/ssh/sshd_config
/bin/sed -i "/echo/s:CentOS:CFIST SSL GATEWAY:" /etc/rc.d/rc.sysinit
/bin/echo "PermitRootLogin no" >>/etc/ssh/sshd_config
/bin/echo "AllowUsers cfist" >>/etc/ssh/sshd_config
/bin/echo "cfist ALL = (ALL) NOPASSWD:ALL" >>/etc/sudoers
/bin/echo "pid_N=\`ps -ef | grep getnet | grep -v grep | awk '{print $2}' | wc -l\`" >> /home/cfist/.bash_profile
/bin/echo "[ \${pid_N} -ge 1 ] || /usr/local/SSLGW_WEB/web/script/monitor/self-check/getnet.sh &" >> /home/cfist/.bash_profile
/usr/sbin/groupadd haclient
/usr/sbin/useradd -g haclient hacluster
/usr/sbin/semanage port -a -t ssh_port_t -p tcp 1357
/bin/mv -f /root/blacklist.conf /etc/modprobe.d/

%clean

%changelog
* Mon Jun 23 2014 Liying Chen<lychen@cfist.com.cn> - 1.0
- Create the file

