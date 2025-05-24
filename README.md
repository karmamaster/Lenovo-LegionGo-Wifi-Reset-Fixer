# Lenovo-LegionGo-Wifi-Reset-Fixer
## ⚠️ License & Credit
This script is distributed for personal use only.  
You are **not allowed to modify or redistribute it without explicit permission**.
Please retain the original credit to the author when sharing:

**Author: [Khang Duong](https://github.com/karmamaster)**
# 🛠️ Safe Wi-Fi Fixer for MT7921/MT7922 on SteamOS (Lenovo Legion Go)

This script is designed to fix unstable Wi-Fi issues on Lenovo Legion Go running SteamOS, specifically for MT7921/MT7922 Wi-Fi chipsets.

---

## ⚙️ Supported Chipsets

- MediaTek **MT7921**
- MediaTek **MT7922**

---

## 📦 Requirements

- SteamOS with terminal access (Decky Loader or Desktop Mode).
- `yay` AUR helper (will be installed automatically if missing).
- Internet connection **at least once** (e.g., tethered via USB or Ethernet).

---

## 🧾 What It Does

- Disables ASPM (PCIe power saving) for MT7921.
- Disables Wi-Fi powersave via NetworkManager.
- Ensures correct backend (`wpa_supplicant`) is used instead of `iwd`.
- Installs the `mt76-dkms-git` driver from AUR if needed.
- Automatically reboots after applying changes.

---

## 🚀 How to Use

### 1. Open Terminal

Switch your Legion Go to **Desktop Mode**, then open **Konsole** or any terminal emulator.

### 2. Download and execute Script

```bash
curl -O https://raw.githubusercontent.com/karmamaster/Lenovo-LegionGo-Wifi-Reset-Fixer/refs/heads/main/legionGo_fix_mt792x_wifi_reset.sh

chmod +x legionGo_fix_mt792x_wifi_reset.sh

bash ./legionGo_fix_mt792x_wifi_reset.sh
```
## Notes

- The script will automatically revert changes if any error occurs.
- If the script fails to detect MT7921/MT7922, it will exit safely.