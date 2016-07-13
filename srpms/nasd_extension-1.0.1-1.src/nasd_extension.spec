Name: nasd_extension
Version: 1.0.1
Release: 1
Vendor: Thecus
Summary: NAS node.js extension library
License: GPL
Group: System
Source0: %{name}.tar.gz
BuildArch: noarch
BuildRoot: /var/tmp/%{name}-buildroot
Requires: nas_img-bin
Requires: nodejs
Requires: nas_nasd
Requires: GraphicsMagick
Requires: libwmf-lite
%description
Nasd extension libraries.

%prep

%setup -q -n %{name}

%build

%install
[ -d ${RPM_BUILD_ROOT} ] && rm -rf ${RPM_BUILD_ROOT}
/bin/mkdir -p ${RPM_BUILD_ROOT}/usr/lib/node
/bin/cp -rf  ${RPM_BUILD_DIR}/%{name}/usr/lib/node/* ${RPM_BUILD_ROOT}/usr/lib/node/

%post

%postun

%clean

%files
%defattr(-,root,root)
/usr/lib/node/*
%define date    %(echo `LC_ALL="C" date +"%a %b %d %Y"`)

%changelog

* %{date} User <rei..rATrottmann.it>
- first Version

