{
  description = "pixeldots (github:pixeldotting/pixeldots): Material You dotfiles for NixOS: Hyprland (Lua config) + a Caelestia-style Quickshell shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Quickshell from git: the shell uses recent APIs (Bluetooth, Pam, UPower, IdleMonitor ...).
    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # System side: Hyprland, PipeWire, NetworkManager, Bluetooth, UPower, portals ...
      nixosModules.default = import ./nix/nixos.nix;

      # User side: shell, Hyprland Lua config, matugen templates, kitty, fish, GTK/Qt, cursor.
      homeManagerModules.default = import ./nix/home.nix inputs;

      packages = forAllSystems (pkgs: import ./nix/scripts.nix { inherit pkgs; });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
