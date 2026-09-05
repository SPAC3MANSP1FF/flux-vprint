Name:           flux-vprint
Version:        1.0.0
Release:        1%{?dist}
Summary:        Turnkey ThinkPad T480 Fingerprint Reader Suite for openSUSE Tumbleweed
License:        GPL-3.0-or-later AND MIT
URL:            https://github.com/SPAC3MANSP1FF/flux-vprint
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

BuildRequires:  python3-devel
BuildRequires:  python3-setuptools
BuildRequires:  systemd-rpm-macros

Requires:       innoextract
Requires:       fprintd
Requires:       fprintd-pam
Requires:       python3-pyusb
Requires:       python3-cryptography
Requires:       python3-dbus-python
Requires:       python3-gobject
Requires:       systemd
Requires:       udev

%description
flux-vprint provides a turnkey background service and management tool for
Validity / Synaptics fingerprint sensors (specifically 06cb:009a on Lenovo ThinkPad T480)
on openSUSE Tumbleweed.
It automatically handles firmware extraction, systemd background daemons,
udev permissions, and openSUSE PAM configuration for seamless KDE Plasma and SDDM login.

%prep
%autosetup

%build
# Pure Python modules built during install

%install
%make_install

%post
%service_add_post open-fprintd.service python3-validity.service open-fprintd-resume.service python3-validity-suspend-hotfix.service
# Enable openSUSE PAM fingerprint authentication
if [ -x /usr/sbin/pam-config ]; then
    /usr/sbin/pam-config -a --fprintd || true
fi
# Automatically extract firmware if network is available
if [ -x %{_prefix}/lib/flux-vprint/fetch-firmware.sh ]; then
    %{_prefix}/lib/flux-vprint/fetch-firmware.sh %{_datadir}/python-validity || true
fi
systemd-tmpfiles --create %{_tmpfilesdir}/flux-vprint.conf 2>/dev/null || true
udevadm control --reload-rules 2>/dev/null || true
udevadm trigger 2>/dev/null || true

%preun
%service_del_preun open-fprintd.service python3-validity.service open-fprintd-resume.service python3-validity-suspend-hotfix.service

%postun
%service_del_postun open-fprintd.service python3-validity.service open-fprintd-resume.service python3-validity-suspend-hotfix.service
if [ $1 -eq 0 ]; then
    if [ -x /usr/sbin/pam-config ]; then
        /usr/sbin/pam-config -d --fprintd || true
    fi
fi

%files
%license LICENSE
%doc README.md
%{_bindir}/flux-vprint
%{_prefix}/lib/flux-vprint/
%{_udevrulesdir}/60-flux-vprint.rules
%{_tmpfilesdir}/flux-vprint.conf
%{_unitdir}/open-fprintd.service
%{_unitdir}/python3-validity.service
%{_unitdir}/open-fprintd-resume.service
%{_unitdir}/python3-validity-suspend-hotfix.service
%dir %{_sysconfdir}/python-validity
%config(noreplace) %{_sysconfdir}/python-validity/dbus-service.yaml
%{_datadir}/dbus-1/system.d/net.reactivated.Fprint.conf
%{_datadir}/dbus-1/system.d/io.github.uunicorn.Fprint.conf
%{python3_sitelib}/validitysensor/
%{python3_sitelib}/openfprintd/
%{python3_sitelib}/*.egg-info
%{_prefix}/lib/python-validity/
%{_prefix}/lib/open-fprintd/

%changelog
* Fri Sep 04 2026 Chris <chris@localhost> - 1.0.0-1
- Initial release of flux-vprint for openSUSE Tumbleweed

