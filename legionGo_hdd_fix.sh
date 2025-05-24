#!/bin/bash

# NOTE: Auto HHD Installer for SteamOS Beta
# This script disables readonly, installs yay-bin if needed, hhd packages, and sets up ACPI for TDP control.

set -e

echo "[1/8] 🔓 Disabling SteamOS read-only mode..."
sudo steamos-readonly disable

echo "[2/8] 🔑 Initializing pacman keys..."
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman-key --populate holo

echo "[3/8] 📦 Installing git and base-devel..."
sudo pacman -S --needed --noconfirm git base-devel

# Check if yay is already installed
if command -v yay >/dev/null 2>&1; then
  echo "[4/8] ✅ yay already installed. Skipping yay-bin installation."
else
  echo "[4/8] 🛠️ Installing yay-bin..."
  git clone https://aur.archlinux.org/yay-bin.git
  cd yay-bin
  makepkg -si --noconfirm
  cd ..
  rm -rf yay-bin
fi

echo "[5/8] ⚙️ Installing hhd, adjustor, hhd-ui via yay..."
yay -S --noconfirm hhd adjustor hhd-ui

echo "[6/8] ⚡ Installing ACPI and Neptune kernel headers..."
sudo pacman -S --noconfirm linux-neptune-611-headers acpi_call-dkms

echo "[7/8] 🖥️ Enabling hhd service..."
sudo systemctl enable --now hhd@$(whoami)

echo "[8/8] 🔁 Rebooting system in 5s to apply changes..."
sleep 5
sudo reboot

