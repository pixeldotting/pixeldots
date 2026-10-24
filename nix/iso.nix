# Live ISO, stage 1: kernel + hardware support + NetworkManager + the pixeldots desktop.
# There is NO installer in the image yet (cage session and the installer UI come in later stages).
#
#   nix build .#nixosConfigurations.iso.config.system.build.isoImage
#
# Imports installation-cd-base.nix, not installation-cd-minimal.nix: the minimal profile sets
# `fonts.fontconfig.enable = lib.mkForce false` (and `isoImage.edition = lib.mkForce "minimal"`), which breaks a
# Qt/Hyprland desktop and cannot be overridden except by another mkForce. The graphical ISOs in nixpkgs
# (installation-cd-graphical-base.nix) import the same installation-cd-base.nix.
# Sources for these choices are listed in docs/logs/iso-stage1-sources.txt.
{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-base.nix") ];

  # Needed because lib.nixosSystem is called without a `system` argument (nixpkgs sets system = null).
  nixpkgs.hostPlatform = "x86_64-linux";

  # NetworkManager is the network stack of the desktop (Wi-Fi panel in the shell talks to nmcli).
  # Newer nixpkgs already enable it in installation-cd-base.nix and older graphical ISOs forced wpa_supplicant off
  # next to it; stating both here is correct for either and cannot conflict (same value / mkForce).
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;
}
