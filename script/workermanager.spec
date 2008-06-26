Summary: Gearman Worker Manager
Name: perl-Gearman-Worker-Manager
Version: 0.1
Release: 1
License: GPL
Group: Development/Libraries
URL: http://d.hatena.ne.jp/stanaka/
#Source0: %{name}-%{version}.tar.gz
Source0: Gearman-Worker-Manager-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch
Requires: perl(Gearman::Worker)
Requires: perl(Parallel::ForkManager)
Requires: perl(Getopt::Std)
Requires: perl(Proc::Daemon)
Requires: perl(File::Pid)

%description

%prep
%setup -q -n gearmanworkermanager

%build

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/bin
mkdir -p $RPM_BUILD_ROOT/etc/sysconfig
mkdir -p $RPM_BUILD_ROOT/etc/init.d
cp bin/gearmanworkermanager.pl $RPM_BUILD_ROOT/usr/bin/
cp config/gearmanworkermanager $RPM_BUILD_ROOT/etc/sysconfig
cp script/gearmanworkermanager.init $RPM_BUILD_ROOT/etc/init.d/gearmanworkermanager

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
/etc/sysconfig/gearmanworkermanager
%attr(755,root,root) /usr/bin/gearmanworkermanager.pl
%attr(755,root,root) /etc/init.d/gearmanworkermanager

%doc


%changelog
* Fri Mar 21 2008 Shinji Tanaka <stanaka@takijiri.hatena.ne.jp> - 
- Initial build.

