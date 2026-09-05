Name:           flux-vprint
Version:        1.0.0
Release:        1%{?dist}
Summary:        Turnkey ThinkPad T480 Fingerprint Reader Suite for openSUSE Tumbleweed
License:        GPL-2.0-only AND MIT
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
Requires:       python3-PyYAML
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
# The vendored python-validity LICENSE and open-fprintd COPYING share a
# basename with the top-level LICENSE (or with each other's convention).
# %license copies by basename into a single shared licensedir, so without
# renaming, one silently overwrites another at the same destination path.
cp core/python-validity/LICENSE LICENSE-python-validity
cp core/open-fprintd/COPYING COPYING-open-fprintd

%build
# Pure Python modules built during install

%install
%make_install

%pre
%service_add_pre open-fprintd.service python3-validity.service open-fprintd-resume.service python3-validity-suspend-hotfix.service

%post
# Disable the stock fprintd service: it and open-fprintd.service both
# claim the net.reactivated.Fprint D-Bus name, so both cannot run at once.
# Mirrors bin/flux-vprint's cmd_install step 2/7.
systemctl stop fprintd.service 2>/dev/null || true
systemctl disable fprintd.service 2>/dev/null || true
systemctl mask fprintd.service 2>/dev/null || true
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
    systemctl unmask fprintd.service 2>/dev/null || true
fi

%files
%license LICENSE
%license LICENSE-python-validity
%license COPYING-open-fprintd
%doc README.md
%doc THIRD-PARTY-LICENSES.md
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
%{_bindir}/validity-led-dance
%{_bindir}/validity-sensors-firmware
%{_datadir}/dbus-1/system-services/net.reactivated.Fprint.service
%{_datadir}/python-validity/playground/

%changelog
* Fri Sep 04 2026 Chris <chris@localhost> - 1.0.0-1
- Initial release of flux-vprint for openSUSE Tumbleweed

