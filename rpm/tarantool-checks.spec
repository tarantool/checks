Name: tarantool-queue
Version: 2.1.0
Release: 1%{?dist}
Summary: Persistent in-memory queues for Tarantool
Group: Applications/Databases
License: MIT
URL: https://github.com/tarantool/checks
Source0: https://github.com/tarantool/%{name}/archive/%{version}/%{name}-%{version}.tar.gz
BuildArch: noarch
BuildRequires: tarantool >= 1.7
BuildRequires: tarantool-devel >= 1.7
Requires: tarantool >= 1.7
%description
Easy, terse, readable and fast function arguments type checking.

%prep
%setup -q -n %{name}-%{version}

%define luapkgdir %{_datadir}/tarantool
%install
%make_install

%files
%{luapkgdir}/checks.lua
%doc README.md
%{!?_licensedir:%global license %doc}
%license LICENSE

%changelog
* Fri Jun 29 2018 Albert Sverdlov <sverdlov@tarantool.org> 2.1.0-1
- Initial version of the RPM spec

