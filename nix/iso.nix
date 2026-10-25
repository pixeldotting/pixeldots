# Live ISO: kernel + hardware support + NetworkManager + the pixeldots desktop, and the installer wizard
# that starts instead of a login (cage on tty1).
#
#   nix build .#nixosConfigurations.iso.config.system.build.isoImage
#
# Imports installation-cd-base.nix, not installation-cd-minimal.nix: the minimal profile sets
# `fonts.fontconfig.enable = lib.mkForce false` (and `isoImage.edition = lib.mkForce "minimal"`), which breaks a
# Qt/Hyprland desktop and cannot be overridden except by another mkForce. The graphical ISOs in nixpkgs
# (installation-cd-graphical-base.nix) import the same installation-cd-base.nix.
# Sources for these choices: docs/logs/iso-stage1-sources.txt and docs/logs/iso-live-sources.txt.
{
  lib,
  pkgs,
  modulesPath,
  self,
  ...
}:

let
  inst = import ./installer.nix { inherit pkgs; };
in
{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-base.nix") ];

  # Needed because lib.nixosSystem is called without a `system` argument (nixpkgs sets system = null).
  nixpkgs.hostPlatform = "x86_64-linux";

  # NetworkManager is the network stack of the desktop (Wi-Fi panel in the shell talks to nmcli).
  # Newer nixpkgs already enable it in installation-cd-base.nix and older graphical ISOs forced wpa_supplicant off
  # next to it; stating both here is correct for either and cannot conflict (same value / mkForce).
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  # The live session: cage (a kiosk Wayland compositor) runs the installer wizard on tty1 instead of a login prompt.
  # services.cage.* are documented NixOS options (nixos/modules/services/wayland/cage.nix); the module's unit
  # `cage-tty1` conflicts with getty@tty1. The other virtual consoles keep the autologin shell of the live image
  # (Ctrl+Alt+F2, e.g. for nmtui when there is no wired network). `-s` allows that VT switching.
  services.cage = {
    enable = true;
    user = "nixos"; # the live user from profiles/installation-device.nix (passwordless sudo)
    program = "${inst.pixeldots-live-session}/bin/pixeldots-live-session";
    extraArguments = [ "-s" ];
  };
  systemd.defaultUnit = lib.mkDefault "graphical.target";

  # What the installer needs to know about this image:
  #  - flake-url: the exact revision this ISO was built from (self.rev exists for a clean git tree), so the installed
  #    system is the same code as the image; without a revision it falls back to the default branch.
  #  - state-version: lib.trivial.release of the nixpkgs this image was built with.
  environment.etc."pixeldots/flake-url".text =
    if self ? rev then "github:pixeldotting/pixeldots/${self.rev}" else "github:pixeldotting/pixeldots";
  environment.etc."pixeldots/state-version".text = lib.trivial.release;
}
