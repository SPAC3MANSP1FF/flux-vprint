# flux-vprint 🔒🖐️

**Turnkey Fingerprint Reader Suite for ThinkPad T480 on openSUSE Tumbleweed**

`flux-vprint` is an automated, zero-headache service and management tool designed to make the **Synaptics MIS Touch fingerprint sensor (`06cb:009a`)** work out of the box on **openSUSE Tumbleweed** with full **KDE Plasma** and **SDDM** login screen support.

---

## 🚀 Quick Start (1-Minute Setup)

You do **not** need to be a developer or tinker with system files. Everything is automated:

### 1. Clone & Run the Installer
```bash
git clone https://github.com/SPAC3MANSP1FF/flux-vprint.git
cd flux-vprint
sudo ./bin/flux-vprint install
```

This single command will:
* ✅ Install needed openSUSE packages (`innoextract`, `pyusb`, `cryptography`, `fprintd-pam`, etc.)
* ✅ Download and extract the official Lenovo firmware directly to persistent storage
* ✅ Deploy the driver and standard D-Bus fingerprint services
* ✅ Configure openSUSE PAM (`pam-config -a --fprintd`) so the login screen, lock screen, and `sudo` recognize your fingerprint
* ✅ Enable sleep/resume hooks so your fingerprint reader continues working after laptop suspend

### 2. Enroll Your Fingerprint
Once installation finishes, you can enroll your finger either through the terminal or directly inside KDE Plasma:

* **Option A (KDE Plasma Settings - Recommended)**:
  1. Open **System Settings**.
  2. Navigate to **Users** (or search "Fingerprint").
  3. Click **Add Fingerprint**, select your finger, and tap the reader repeatedly until complete.
* **Option B (Command Line)**:
  ```bash
  flux-vprint enroll
  ```

### 3. Log In!
Lock your screen (`Super + L`) or log out. Tap your finger on the sensor at the SDDM login screen to log in!

---

## 🛠️ Handy Commands

| Command | Purpose |
| :--- | :--- |
| `flux-vprint status` | Shows a colorized dashboard of sensor hardware, firmware, services, and PAM. |
| `flux-vprint enroll` | Guided walkthrough to enroll a new finger. |
| `flux-vprint test` | Quick test to verify that the sensor recognizes your finger. |
| `sudo flux-vprint reset` | Clears hardware pairing keys (run this if the sensor was previously used in Windows). |
| `sudo flux-vprint fetch-fw` | Re-downloads and extracts the firmware if ever needed. |
| `sudo flux-vprint uninstall` | Cleanly uninstalls the services and restores default openSUSE PAM settings. |

---

## 🩺 Health Check & Diagnostics

Check the state of your fingerprint system anytime:

```bash
flux-vprint status
```

Example healthy output:
```text
System & Fingerprint Reader Health Check:

  [1/5] Hardware Sensor (USB): DETECTED (Bus 001 Device 007: ID 06cb:009a Synaptics, Inc.)
  [2/5] Proprietary Firmware:  INSTALLED (/usr/share/python-validity/6_07f_lenovo_mis_qm.xpfwext)
        Active Runtime Link:   OK (/run/python-validity/6_07f_lenovo_mis_qm.xpfwext)
  [3/5] Validity Driver Service: ACTIVE (Running)
        Open-Fprintd D-Bus:      ACTIVE (Running)
        Resume / Sleep Hook:     ENABLED
  [4/5] openSUSE PAM Auth:       ENABLED (Fingerprint login & sudo active)
  [5/5] Enrolled Fingers (chris): ENROLLED
         - #0: right-index-finger
```

---

## 🗑️ Uninstallation

If you ever want to remove `flux-vprint` completely and revert back to your original openSUSE configuration:

```bash
sudo flux-vprint uninstall
```
*(Or if you haven't installed the global shortcut yet: `sudo ./bin/flux-vprint uninstall`)*

This cleanly:
* ✅ Reverts openSUSE PAM (`pam-config -d --fprintd`) so your system returns to standard password authentication
* ✅ Stops and disables all fingerprint services
* ✅ Unmasks the default `fprintd` service
* ✅ Removes all created systemd services, udev rules, D-Bus policies, and firmware files

---

## ❓ Troubleshooting

### The sensor was used in Windows and isn't responding
If you previously registered your fingerprint in Windows on this laptop, the hardware stores pairing keys tied to Windows.
Run:
```bash
sudo flux-vprint reset
```
This resets the sensor crypto pairing keys so Linux can claim the device.

### Sensor stops responding after waking from sleep
`flux-vprint` automatically installs `open-fprintd-resume.service` and `python3-validity-suspend-hotfix.service` to reset the USB bus on wake. If you ever run into a hiccup after deep sleep, simply run:
```bash
sudo systemctl restart python3-validity.service open-fprintd.service
```

---

## 📦 Project Structure

```text
flux-vprint/
├── bin/
│   └── flux-vprint            # Main user-friendly CLI management tool
├── config/
│   ├── 60-flux-vprint.rules   # udev permissions for USB sensor (06cb:009a)
│   ├── flux-vprint-tmpfiles.conf # tmpfiles.d config keeping firmware linked across reboots
│   ├── dbus-service.yaml      # SID mapping configuration
│   ├── net.reactivated.Fprint.conf # D-Bus system policy
│   └── io.github.uunicorn.Fprint.conf # Driver D-Bus system policy
├── core/
│   ├── python-validity/       # Low-level USB protocol & crypto driver
│   └── open-fprintd/          # D-Bus fprintd provider for KDE Plasma/SDDM
├── firmware/
│   └── fetch-firmware.sh      # Firmware downloader & innoextract unpacker
├── systemd/
│   ├── python3-validity.service # Hardware communication service
│   ├── open-fprintd.service     # D-Bus authentication daemon
│   ├── open-fprintd-resume.service # Wakeup resume hook
│   └── python3-validity-suspend-hotfix.service # Sleep hotfix service
├── rpm/
│   └── flux-vprint.spec       # openSUSE Tumbleweed RPM package spec
├── .vscode/
│   ├── settings.json          # Recommended IDE settings
│   └── tasks.json             # 1-click VS Code tasks (Status, Install, Enroll, Test)
├── Makefile                   # Installation & deployment automation
├── README.md
└── LICENSE                    # GPL-3.0 License
```

---

## 📄 License
This project combines components licensed under GPL-3.0 and MIT. See the `LICENSE` file for full terms.

