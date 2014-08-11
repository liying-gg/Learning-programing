Name: LoadBalance
Summary: CFIST SSL GATEWAY LOAD BALANCE
Version: vvv
Release: rrr
License: CFIST
Group: Development
Vendor: CFIST
Packager: CFIST <http://www.cfist.com.cn>
Distribution: linux
BuildRoot: %{_tmppath}/%{name}-root
AutoReqProv: no

%define _buildshell /bin/bash

%description
CFIST SSL GATEWAY LOAD BALANCE

%files
%attr(0755, cfist, cfist) /etc/init.d/socketLoadBalance
%attr(0755, cfist, cfist) /usr/local/LoadBalance/

%clean

%changelog
* Mon Jun 23 2014 Liying Chen<lychen@cfist.com.cn> - 1.0
- Create the file

