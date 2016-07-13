Name:           nas_agent3
Version:        1.0.0
Release:        2
Summary:	pic control tool
License:        GPLv2
URL:            agent3
Group:          System Environment/Tools
Source0:        %{name}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-buildroot
BuildRequires:  sqlite-devel

%description
pic control tool

%prep

%setup -q -n %{name}

%build
make

%install
#rm -rf $RPM_BUILD_ROOT

#make install
mkdir $RPM_BUILD_ROOT/usr
mkdir $RPM_BUILD_ROOT%{_bindir}
install ./dist/Debug/GNU-Linux-x86/agent3 $RPM_BUILD_ROOT%{_bindir}

%clean
rm -rf $RPM_BUILD_ROOT

%files

%defattr(-,root,root)

%{_bindir}/agent3

%changelog
