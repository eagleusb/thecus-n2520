Name: nas_ddns
Version: 1.0.3
Release: 1
Summary: DDNS server and client
License: GPL
Group: Applications/System
Source0: %{name}.tar.gz
BuildRoot: /var/tmp/%{name}-buildroot

Requires: openssl
BuildRequires: openssl-devel, mysql-devel

%description
DDNS

%package client
Summary: DDNS client programs
Group: Applications/System

%description client
DDNS client programs


%prep

%setup -q -n %{name}


%build

%ifarch ppc
  make COPTS=-DBIGENDIAN
%else
  make
%endif


%install

[ -d ${RPM_BUILD_ROOT} ] && rm -rf ${RPM_BUILD_ROOT}
/bin/mkdir -p ${RPM_BUILD_ROOT}
/bin/mkdir -p ${RPM_BUILD_ROOT}/usr/bin
/bin/mkdir -p ${RPM_BUILD_ROOT}/opt/ddns_client/shell

/bin/cp -f ${RPM_BUILD_DIR}/%{name}/ddns_client			${RPM_BUILD_ROOT}/usr/bin/
/bin/cp -f ${RPM_BUILD_DIR}/%{name}/shell/module.rc		${RPM_BUILD_ROOT}/opt/ddns_client/shell/

%post client
/opt/ddns_client/shell/module.rc remove >/dev/null 2>&1 || :
/opt/ddns_client/shell/module.rc boot >/dev/null 2>&1 || :

%preun client
#If the latest version is erased, clean up the environment
if [ "$1" = "0" ] ;then
	/opt/ddns_client/shell/module.rc remove >/dev/null 2>&1 || :
fi

%clean

rm -rf ${RPM_BUILD_DIR}


%files client

%defattr(-,root,root)
/usr/bin/ddns_client
/opt/ddns_client/shell/module.rc
