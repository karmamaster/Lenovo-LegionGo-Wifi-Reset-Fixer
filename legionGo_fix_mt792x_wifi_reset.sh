#!/bin/bash
# ==========================================================
# 🛠️ Safe Wi-Fi Fixer for MT7921/MT7922 on SteamOS (Legion Go)
# Author: duongkhang-dev
#
# 📌 License Notice:
# This script is provided "as-is" for personal use only.
# You are NOT allowed to:
# - Modify or redistribute without permission.
# - Remove or alter the credit line above.
#
# Please credit the original author when sharing.
# ==========================================================

set -e
CURRENT_STEP="Startup"

rollback() {
  echo -e "\n[‼️] Error at step: $CURRENT_STEP"
  echo "[!] Reverting to original configuration..."
  sudo rm -f /etc/modprobe.d/mt7921.conf
  sudo rm -f /etc/NetworkManager/conf.d/wifi-powersave.conf
  sudo sed -i '/^\[device\]/d;/^wifi.backend/d' /etc/NetworkManager/NetworkManager.conf 2>/dev/null || true
  sudo systemctl unmask iwd
  sudo systemctl enable --now iwd
  echo "[✔] Revert completed. Please check your Wi-Fi connection."
  exit 1
}

trap rollback ERR

CURRENT_STEP="Checking Wi-Fi chip"
echo "[*] Checking Wi-Fi chip..."
wifi_chip=$(lspci | grep -i "MT792" | grep -o "MT792[12]")

if [[ "$wifi_chip" != "MT7921" && "$wifi_chip" != "MT7922" ]]; then
  echo "[!] MT7921 or MT7922 not detected. Exiting script."
  exit 1
fi
echo "[+] Detected: $wifi_chip"

CURRENT_STEP="Checking current backend"
echo "[*] Checking current NetworkManager backend..."
iwd_active=$(systemctl is-active iwd)
wpa_active=$(systemctl is-active wpa_supplicant)

echo "[i] iwd status: $iwd_active"
echo "[i] wpa_supplicant status: $wpa_active"

CURRENT_STEP="Disabling ASPM"
echo "[*] Disabling ASPM (PCIe Power saving)..."
echo 'options mt7921e disable_aspm=1' | sudo tee /etc/modprobe.d/mt7921.conf

CURRENT_STEP="Disabling Wi-Fi PowerSave"
echo "[*] Disabling Wi-Fi PowerSave..."
sudo mkdir -p /etc/NetworkManager/conf.d
echo -e "[connection]\nwifi.powersave = 2" | sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf

CURRENT_STEP="Checking or installing mt76-dkms-git"
echo "[*] Checking and installing mt76-dkms-git driver if necessary..."
if ! pacman -Q mt76-dkms-git &>/dev/null; then
  if ! command -v yay &>/dev/null; then
    CURRENT_STEP="Installing yay"
    echo "[!] 'yay' not found. Installing..."
    sudo pacman -S --noconfirm yay || rollback
  fi
  CURRENT_STEP="Installing mt76-dkms-git"
  yay -S --noconfirm mt76-dkms-git || rollback
else
  echo "[✓] mt76-dkms-git already installed. Skipping."
fi

# ========== CONFIGURE WPA_BACKEND if NOT active ==========
if [[ "$wpa_active" != "active" ]]; then
  CURRENT_STEP="Setting wpa_supplicant as backend"
  echo "[*] Setting wpa_supplicant as backend..."

  sudo sed -i '/^\[device\]/d;/^wifi.backend/d' /etc/NetworkManager/NetworkManager.conf 2>/dev/null || true
  echo -e "[device]\nwifi.backend=wpa_supplicant" | sudo tee -a /etc/NetworkManager/NetworkManager.conf

  if [[ "$iwd_active" == "active" ]]; then
    CURRENT_STEP="Disabling IWD"
    echo "[*] Disabling IWD..."
    sudo systemctl stop iwd
    sudo systemctl disable --now iwd
    sudo systemctl mask iwd
  fi

  CURRENT_STEP="Enabling wpa_supplicant"
  echo "[*] Enabling wpa_supplicant..."
  sudo systemctl enable --now wpa_supplicant || rollback

  CURRENT_STEP="Restarting NetworkManager"
  echo "[*] Restarting NetworkManager..."
  sudo systemctl restart NetworkManager
else
  echo "[✓] wpa_supplicant is already active. Skipping backend config."
fi

echo -e "\n[✔] Wi-Fi fix completed for $wifi_chip. System will reboot in 10 seconds..."
sleep 10
sudo reboot