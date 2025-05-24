#!/bin/bash

# NOTE: Safe Wi-Fi Fixer for MT7921/MT7922 on SteamOS (Legion Go)

set -e

rollback() {
  echo "[!] Đã xảy ra lỗi. Đang khôi phục cấu hình ban đầu..."
  sudo rm -f /etc/modprobe.d/mt7921.conf
  sudo rm -f /etc/NetworkManager/conf.d/wifi-powersave.conf
  sudo sed -i '/^\[device\]/d;/^wifi.backend/d' /etc/NetworkManager/NetworkManager.conf 2>/dev/null || true
  sudo systemctl unmask iwd
  sudo systemctl enable --now iwd
  echo "[✔] Khôi phục hoàn tất. Vui lòng kiểm tra lại kết nối Wi-Fi."
  exit 1
}

trap rollback ERR

echo "[*] Kiểm tra chip Wi-Fi..."
wifi_chip=$(lspci | grep -i "MT792" | grep -o "MT792[12]")

if [[ "$wifi_chip" != "MT7921" && "$wifi_chip" != "MT7922" ]]; then
  echo "[!] Không phát hiện MT7921 hoặc MT7922. Dừng script."
  exit 1
fi
echo "[+] Phát hiện: $wifi_chip"

echo "[*] Kiểm tra backend hiện tại của NetworkManager..."
iwd_active=$(systemctl is-active iwd)
wpa_active=$(systemctl is-active wpa_supplicant)

echo "[i] iwd status: $iwd_active"
echo "[i] wpa_supplicant status: $wpa_active"

echo "[*] Tắt ASPM (PCIe Power saving)..."
echo 'options mt7921e disable_aspm=1' | sudo tee /etc/modprobe.d/mt7921.conf

echo "[*] Tắt PowerSave cho Wi-Fi..."
sudo mkdir -p /etc/NetworkManager/conf.d
echo -e "[connection]\nwifi.powersave = 2" | sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf

echo "[*] Kiểm tra và cài driver mt76-dkms-git nếu cần..."
if ! pacman -Q mt76-dkms-git &>/dev/null; then
  if ! command -v yay &>/dev/null; then
    echo "[!] Không tìm thấy 'yay'. Đang cài..."
    sudo pacman -S --noconfirm yay || rollback
  fi
  yay -S --noconfirm mt76-dkms-git || rollback
else
  echo "[✓] mt76-dkms-git đã được cài, bỏ qua."
fi

echo "[*] Cấu hình NetworkManager dùng wpa_supplicant..."
sudo sed -i '/^\[device\]/d;/^wifi.backend/d' /etc/NetworkManager/NetworkManager.conf 2>/dev/null || true
echo -e "[device]\nwifi.backend=wpa_supplicant" | sudo tee -a /etc/NetworkManager/NetworkManager.conf

if [[ "$iwd_active" == "active" ]]; then
  echo "[*] Tắt IWD hoàn toàn..."
  sudo systemctl stop iwd
  sudo systemctl disable iwd
  sudo systemctl mask iwd
fi

echo "[*] Bật wpa_supplicant..."
sudo systemctl enable --now wpa_supplicant || rollback

echo "[*] Khởi động lại NetworkManager..."
sudo systemctl restart NetworkManager

echo "[✔] Hoàn tất fix Wi-Fi cho $wifi_chip. Hệ thống sẽ khởi động lại sau 5 giây..."
sleep 5
sudo reboot
