%define build_version 1.0.0.1016

Name:           libinvm-i18n
Version:        %{build_version}
Release:        3%{?dist}
Summary:        Internationalization library
License:        BSD
Group:          Development/Libraries
URL:            https://01.org/intel-nvm-i18n-library
Source:         https://github.com/01org/libinvm-i18n/archive/v%{version}.tar.gz#/%{name}-%{version}.tar.gz
ExclusiveArch:  x86_64

%description
Framework library for Internationalization, supporting a subset of
Internationalization (I18n) functionality. This is a required library
for using libinvm-cli library.

%package -n %{name}-devel
Summary:        Development files for %{name}
License:        BSD
Group:          Development/Libraries
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description -n %{name}-devel
The %{name}-devel package contains header files for
developing applications that use %{name}.

%prep
%setup -q -n %{name}-%{version}

%build
make BUILDNUM=%{build_version} RELEASE=1 CFLAGS_EXTERNAL="%{?optflags}" %{?_smp_mflags}

%install
make install RELEASE=1 RPM_ROOT=%{buildroot} LIB_DIR=%{_libdir} INCLUDE_DIR=%{_includedir}

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig

%files
%doc README.md
%{_libdir}/libinvm-i18n.so.*
%license licenses/intel_bsd
%license licenses/netbsd

%files -n %{name}-devel
%doc README.md
%{_libdir}/libinvm-i18n.so
%{_includedir}/libinvm-i18n
%license licenses/intel_bsd
%license licenses/netbsd

%changelog
* Fri Aug 12 2016 Jeff Moyer <jmoyer@redhat.com> - 1.0.0.1016-3.el7
- Fix broken import from fedora
  Resolves: rhbz#1326924

* Thu Aug 11 2016 Dave Anderson <anderson@redhat.com> - 1.0.0.1016-2.el7
- Build for x86_64 only
  Resolves: rhbz#1326924

* Thu Aug 11 2016 Dave Anderson <anderson@redhat.com> - 1.0.0.1016-1.el7
- Initial RHEL7 import
  Resolves: rhbz#1326924

* Thu Mar 24 2016 Richard Johnson <richard.a.johnson@intel.com> - 1.0.0.1016-1
- Initial rpm release
