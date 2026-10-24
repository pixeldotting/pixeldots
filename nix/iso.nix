# Live ISO: kernel + hardware support + NetworkManager + the pixeldots desktop, and the installer UI that starts
# instead of a login prompt (cage kiosk on tty1).
#
#   nix build .#nixosConfigurations.iso.config.system.build.isoImage
#
# Imports installation-cd-base.nix, not installation-cd-minimal.nix: the minimal profile sets
# `fonts.fontconfig.enable = lib.mkForce false` (and `isoImage.edition = lib.mkForce "minimal"`), which breaks a
# Qt/Hyprland desktop and cannot be overridden except by another mkForce. The graphical ISOs in nixpkgs
# (installation-cd-graphical-base.nix) import the same installation-cd-base.nix.
# Sources for these choices are listed in docs/logs/iso-stage1-sources.txt and iso-stage2-sources.txt.
{
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  installer = import ./installer.nix { inherit pkgs; };

  # Stage 3 (install to disk) does not exist yet. apply.sh from the checkout rebuilds the RUNNING system, which is
  # meaningless on a live ISO, so the live session gets this stub: the UI shows a clear failure instead.
  liveApply = pkgs.writeShellScript "pixeldots-live-apply" ''
    cat > /dev/null # the UI sends the password on stdin; it is not read, not stored, not printed
    echo "@@ 5 Checking"
    echo "Installing to a disk is not implemented in this ISO yet."
    echo "Nothing was changed on this computer."
    exit 1
  '';

  # Runs inside cage. Data files (font, locales, apps list ...) are copied into the store with the flake source.
  liveSession = pkgs.writeShellScript "pixeldots-live-session" ''
    export PD_APPLY=${liveApply}
    export PD_DEFAULT_USER=nixos
    export PD_LOG=/tmp/pixeldots-install.log
    export XKB_DEFAULT_LAYOUT=us
    exec ${installer.pixeldots-installer}/bin/pixeldots-installer ${../installer/data}
  '';
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

  # The live session: cage (kiosk compositor) on tty1 as the ISO's "nixos" user, running the installer UI.
  # Options enable/user/program/extraArguments of services.cage: nixos/modules/services/wayland/cage.nix.
  services.cage = {
    enable = true;
    user = "nixos";
    program = "${liveSession}";
    extraArguments = [ "-s" ]; # allow VT switching (Ctrl+Alt+F2 gives a shell if the UI misbehaves)
  };
  systemd.defaultUnit = "graphical.target"; # cage-tty1.service is wanted by graphical.target

  # The UI is software-rendered 2D, so wlroots' CPU renderer is enough and also works in VMs without a GPU.
  # wlroots reads WLR_RENDERER when the compositor (cage) starts, hence the service environment, not the program wrapper.
  systemd.services."cage-tty1".environment = {
    WLR_RENDERER = "pixman";
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
