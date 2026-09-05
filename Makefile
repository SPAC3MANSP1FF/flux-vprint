# ==============================================================================
# Makefile for flux-vprint (openSUSE Tumbleweed)
# ==============================================================================

PREFIX ?= /usr
DESTDIR ?=
SYSCONFDIR ?= /etc
LIBDIR ?= $(PREFIX)/lib
BINDIR ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share
UDEVRULESDIR ?= $(LIBDIR)/udev/rules.d
SYSTEMDUNITDIR ?= $(LIBDIR)/systemd/system
TMPFILESDIR ?= $(LIBDIR)/tmpfiles.d
DBUSDIR ?= $(DATADIR)/dbus-1/system.d

.PHONY: all install uninstall clean rpm status

all:
	@echo "flux-vprint is ready. Run 'sudo make install' or 'sudo ./bin/flux-vprint install'."

install:
	@echo "Installing flux-vprint..."
	install -d -m 0755 $(DESTDIR)$(BINDIR)
	install -d -m 0755 $(DESTDIR)$(LIBDIR)/flux-vprint
	install -d -m 0755 $(DESTDIR)$(UDEVRULESDIR)
	install -d -m 0755 $(DESTDIR)$(SYSTEMDUNITDIR)
	install -d -m 0755 $(DESTDIR)$(TMPFILESDIR)
	install -d -m 0755 $(DESTDIR)$(DBUSDIR)
	install -d -m 0755 $(DESTDIR)$(SYSCONFDIR)/python-validity
	install -d -m 0755 $(DESTDIR)$(DATADIR)/python-validity

	# CLI Tool
	install -m 0755 bin/flux-vprint $(DESTDIR)$(BINDIR)/flux-vprint

	# Firmware Fetcher
	install -m 0755 firmware/fetch-firmware.sh $(DESTDIR)$(LIBDIR)/flux-vprint/fetch-firmware.sh

	# Configuration
	install -m 0644 config/60-flux-vprint.rules $(DESTDIR)$(UDEVRULESDIR)/60-flux-vprint.rules
	install -m 0644 config/flux-vprint-tmpfiles.conf $(DESTDIR)$(TMPFILESDIR)/flux-vprint.conf
	install -m 0644 config/dbus-service.yaml $(DESTDIR)$(SYSCONFDIR)/python-validity/dbus-service.yaml
	install -m 0644 config/net.reactivated.Fprint.conf $(DESTDIR)$(DBUSDIR)/net.reactivated.Fprint.conf
	install -m 0644 config/io.github.uunicorn.Fprint.conf $(DESTDIR)$(DBUSDIR)/io.github.uunicorn.Fprint.conf

	# Systemd Units
	install -m 0644 systemd/python3-validity.service $(DESTDIR)$(SYSTEMDUNITDIR)/python3-validity.service
	install -m 0644 systemd/open-fprintd.service $(DESTDIR)$(SYSTEMDUNITDIR)/open-fprintd.service
	install -m 0644 systemd/open-fprintd-resume.service $(DESTDIR)$(SYSTEMDUNITDIR)/open-fprintd-resume.service
	install -m 0644 systemd/python3-validity-suspend-hotfix.service $(DESTDIR)$(SYSTEMDUNITDIR)/python3-validity-suspend-hotfix.service

	# Python Core Drivers
	cd core/open-fprintd && python3 setup.py install --prefix=$(PREFIX) --root=$(if $(DESTDIR),$(DESTDIR),/)
	cd core/python-validity && python3 setup.py install --prefix=$(PREFIX) --root=$(if $(DESTDIR),$(DESTDIR),/)

uninstall:
	@echo "Uninstalling flux-vprint..."
	rm -f $(DESTDIR)$(BINDIR)/flux-vprint
	rm -rf $(DESTDIR)$(LIBDIR)/flux-vprint
	rm -f $(DESTDIR)$(UDEVRULESDIR)/60-flux-vprint.rules
	rm -f $(DESTDIR)$(TMPFILESDIR)/flux-vprint.conf
	rm -f $(DESTDIR)$(SYSCONFDIR)/python-validity/dbus-service.yaml
	rm -f $(DESTDIR)$(DBUSDIR)/net.reactivated.Fprint.conf
	rm -f $(DESTDIR)$(DBUSDIR)/io.github.uunicorn.Fprint.conf
	rm -f $(DESTDIR)$(SYSTEMDUNITDIR)/python3-validity.service
	rm -f $(DESTDIR)$(SYSTEMDUNITDIR)/open-fprintd.service
	rm -f $(DESTDIR)$(SYSTEMDUNITDIR)/open-fprintd-resume.service
	rm -f $(DESTDIR)$(SYSTEMDUNITDIR)/python3-validity-suspend-hotfix.service
	rm -rf $(DESTDIR)$(LIBDIR)/python-validity
	rm -rf $(DESTDIR)$(LIBDIR)/open-fprintd
	rm -rf $(DESTDIR)$(DATADIR)/python-validity
	rm -rf $(DESTDIR)$(SYSCONFDIR)/python-validity

clean:
	rm -rf build dist *.egg-info
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true

status:
	@./bin/flux-vprint status

