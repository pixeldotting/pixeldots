# System-level pieces the desktop needs. Import it next to the home-manager module:
#   imports = [ pixeldots.nixosModules.default ];
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Hyprland 0.55+ is required: the config is written in Lua.
  programs.hyprland.enable = true;

  assertions = [
    {
      assertion = lib.versionAtLeast config.programs.hyprland.package.version "0.55";
      message = ''
        pixeldots needs Hyprland >= 0.55 (Lua configuration), but ${config.programs.hyprland.package.version}
        is selected. Use nixos-unstable or point programs.hyprland.package at a newer build.
      '';
    }
  ];

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Things the shell talks to
  networking.networkmanager.enable = lib.mkDefault true; # Wi-Fi panel (nmcli)
  hardware.bluetooth.enable = lib.mkDefault true; # Bluetooth panel
  services.upower.enable = true; # battery
  services.power-profiles-daemon.enable = lib.mkDefault true; # power profile chips
  services.gvfs.enable = true; # trash / mounts in the file manager
  services.udisks2.enable = true;
  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true; # GTK colour-scheme switching

  # Authentication dialogs (started from the Hyprland autostart)
  security.polkit.enable = true;
  systemd.user.services.hyprpolkitagent = {
    description = "Hyprland polkit authentication agent";
    serviceConfig = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
    };
  };

  # Portals: screen sharing via Hyprland, file dialogs via GTK
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.hyprland.default = [
      "hyprland"
      "gtk"
    ];
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # The lock screen authenticates through the "login" PAM service, which NixOS always provides.
}
