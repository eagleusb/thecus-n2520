Name: nas_nasd
Version: 1.1.5
Release: 1
Vendor: Thecus
Summary: NAS Deamon
###################################################################
# SubPackage parameter(s) below is/are for Thecus package using.
# The format is:
# %define SubPackage[N] <git repository> <tag>
###################################################################
%define SubPackage0 nasd_service/nasd_curl 1.0.0
%define SubPackage1 nasd_service/nasd_ddns 1.0.1
%define SubPackage2 nasd_service/nasd_facebook 1.0.0
%define SubPackage3 nasd_service/nasd_hardware 1.0.0
%define SubPackage4 nasd_service/nasd_history 1.0.0
%define SubPackage5 nasd_service/nasd_network 1.0.0
%define SubPackage6 nasd_service/nasd_rsync 1.0.1
%define SubPackage7 nasd_service/nasd_storage 1.0.1
%define SubPackage8 nasd_service/nasd_system 1.0.2
%define SubPackage9 nasd_service/nasd_thumb 1.0.0
%define SubPackage10 nasd_service/nasd_torrent 1.0.0
%define SubPackage11 nasd_service/nasd_usb 1.0.2
License: GPL
Group: System
Source0: %{name}.tar.gz
Source1: nasd_curl.tar.gz
Source2: nasd_ddns.tar.gz
Source3: nasd_facebook.tar.gz
Source4: nasd_hardware.tar.gz
Source5: nasd_history.tar.gz
Source6: nasd_network.tar.gz
Source7: nasd_rsync.tar.gz
Source8: nasd_storage.tar.gz
Source9: nasd_system.tar.gz
Source10: nasd_thumb.tar.gz
Source11: nasd_torrent.tar.gz
Source12: nasd_usb.tar.gz
BuildRoot: /var/tmp/%{name}-buildroot
Requires: nodejs
Requires: nas_forever
Requires: nas_img-bin >= 1.6.7-1
Requires: nasd_extension >= 1.0.1-1
BuildRequires: nodejs
%description
Nasd deamon

%prep
rm -rf $RPM_SOURCE_DIR/%{name}

%setup -q -n %{name}

%build
cd  ${RPM_BUILD_DIR}/%{name}/opt/%{name}
mkdir -p service
tar xfz %{SOURCE1} -C service
tar xfz %{SOURCE2} -C service
tar xfz %{SOURCE3} -C service
tar xfz %{SOURCE4} -C service
tar xfz %{SOURCE5} -C service
tar xfz %{SOURCE6} -C service
tar xfz %{SOURCE7} -C service
tar xfz %{SOURCE8} -C service
tar xfz %{SOURCE9} -C service
tar xfz %{SOURCE10} -C service
tar xfz %{SOURCE11} -C service
tar xfz %{SOURCE12} -C service

sh make.sh
rm -f make.sh
cd ..
tar czvf %{name}-%{version}-%{release}.tar.gz %{name}

%install
/bin/mkdir -p ${RPM_BUILD_ROOT}/opt/
/bin/cp -rf  ${RPM_BUILD_DIR}/%{name}/opt/nas_nasd ${RPM_BUILD_ROOT}/opt

%post
/opt/nas_nasd/shell/module.rc restart

USER_NAME=`/bin/cat /etc/passwd | /bin/grep x:97:97: | /bin/grep -v ^admin | /bin/awk -F ':' '{print $1}'`
if [ "${USER_NAME}" != "" ]; then
    MAX_UID=`/bin/cat /etc/passwd | /bin/awk -F ':' '{print $3}' | /bin/sort -n | /usr/bin/tail -n 1`
    NEW_UID=$(($MAX_UID + 1))
    usermod -u "$NEW_UID" -g 100 "$USER_NAME"
fi

%postun

%clean

%files
%defattr(-,root,root)
/opt/nas_nasd/*
%define date    %(echo `LC_ALL="C" date +"%a %b %d %Y"`)

%changelog

* %{date} User <kenny_wu@thecus.com>
- first Version

