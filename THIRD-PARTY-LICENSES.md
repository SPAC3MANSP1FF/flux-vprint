# Third-Party Licenses

flux-vprint is licensed under the GNU General Public License v2.0 only
(see `LICENSE`). It vendors modified copies of two upstream projects
under `core/`, each retaining its own original license. This file
documents what's included, where it came from, and what was changed.

## python-validity

- **Location in this repo:** `core/python-validity/`
- **License:** MIT (see `core/python-validity/LICENSE`)
- **Copyright:** (c) 2020 uunicorn
- **Upstream:** https://github.com/uunicorn/python-validity

MIT-licensed code is redistributed here as part of a combined GPLv2
work; this is permitted, and the original MIT copyright notice and
license text are preserved unmodified in `core/python-validity/LICENSE`.

**Modifications made by flux-vprint** (all changes are marked inline
with `flux-vprint patch` comments in the affected source files):

- `validitysensor/usb.py` (`send_init`): added a retry loop for a
  transient busy status (`0x0401`) returned by the 06cb:009a sensor on
  cold init, instead of failing on the first busy reply.
- `validitysensor/init.py` (`open_common`): reordered `usb.send_init()`
  to run before `init_flash()`, fixing flash-command timeouts on this
  hardware.
- `validitysensor/flash.py` (`get_flash_info`): a short (status-only)
  response is now treated as an uninitialized flash instead of crashing
  on an assumed 14-byte header.
- `validitysensor/flash.py` (`get_fw_info`): a "signature validation
  failed" status (`0x044f`) on the fwext partition is now treated the
  same as "no firmware detected," triggering a fresh firmware upload
  instead of crashing.

Root cause and upstream discussion:
https://github.com/uunicorn/python-validity/issues/272

## open-fprintd

- **Location in this repo:** `core/open-fprintd/`
- **License:** GNU General Public License v2.0 only (see
  `core/open-fprintd/COPYING`)
- **Upstream:** https://github.com/uunicorn/open-fprintd

Included and redistributed under the same GPLv2 terms as the rest of
this repository. No functional modifications have been made to this
component as of this writing.

## flux-vprint itself

Everything outside `core/` (the `bin/flux-vprint` CLI, systemd units,
udev rules, D-Bus policy files, installer, and documentation) is
original work licensed under GPLv2-only, consistent with the copyleft
requirements of the bundled `open-fprintd` component.
