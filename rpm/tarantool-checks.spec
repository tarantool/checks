Name: tarantool-checks
Version: 2.1.0
Release: 1%{?dist}
Summary: Easy, terse, readable and fast function arguments type checking
Group: Applications/Databases
License: MIT
URL: https://github.com/tarantool/checks
Source0: https://github.com/tarantool/%{name}/archive/%{version}/%{name}-%{version}.tar.gz
BuildArch: noarch
BuildRequires: tarantool >= 1.6.8.0
Requires: tarantool >= 1.6.8.0
%description
Easy, terse, readable and fast function arguments type checking.

%define luapkgdir %{_datadir}/tarantool
%define br_luapkgdir %{buildroot}%{luapkgdir}

%prep
%setup -q -n %{name}-%{version}

%install
mkdir -p %{br_luapkgdir}
mkdir -p %{br_luapkgdir}/override
cp -av checks.lua %{br_luapkgdir}
cp -rv checks %{br_luapkgdir}
cp -av checks.lua %{br_luapkgdir}/override
cp -rv checks %{br_luapkgdir}/override

%files
%{luapkgdir}/checks.lua
%{luapkgdir}/checks
%{luapkgdir}/override/checks.lua
%{luapkgdir}/override/checks

%doc README.md
%{!?_licensedir:%global license %doc}
%license LICENSE

%changelog
* Fri Jun 29 2018 Albert Sverdlov <sverdlov@tarantool.org> 2.1.0-1
- Initial version of the RPM spec

