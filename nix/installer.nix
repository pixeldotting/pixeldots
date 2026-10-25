# Installer UI (C++/SDL2) and the pieces around it.
#  - pixeldots-installer / pixeldots-installer-session: for an already installed NixOS (installer/bootstrap.sh).
#    apply.sh and data/ are NOT used from the store there: the bootstrapper runs them from the git checkout,
#    because the generated system config points programs.material.repoPath at that checkout.
#  - pixeldots-live-session / pixeldots-install-iso / pixeldots-disks / pixeldots-installer-data: for the live ISO (nix/iso.nix).
{ pkgs }:

let
  lib = pkgs.lib;

  # Runtime data of the UI (font atlas, lists of locales/layouts/time zones/apps).
  data = pkgs.runCommand "pixeldots-installer-data" { } ''
    mkdir -p $out
    cp -r ${../installer/data}/. $out/
  '';

  # ISO mode: the scripts live in the Nix store and get their tools from store paths.
  # udevadm, nixos-install and nixos-generate-config come from the live system (/run/current-system/sw/bin, appended by the script).
  disks = pkgs.writeShellScriptBin "pixeldots-disks" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.util-linux
        pkgs.coreutils
        pkgs.gnugrep
      ]
    }:$PATH
    exec ${pkgs.bash}/bin/bash ${../installer/disks.sh} "$@"
  '';

  installIso = pkgs.writeShellScriptBin "pixeldots-install-iso" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.util-linux
        pkgs.parted
        pkgs.dosfstools
        pkgs.e2fsprogs
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.gnused
        pkgs.curl
        pkgs.openssl
      ]
    }:$PATH
    export PD_DATA_DIR=${data}
    export PD_DISKS_CMD=${disks}/bin/pixeldots-disks
    exec ${pkgs.bash}/bin/bash ${../installer/install-iso.sh} "$@"
  '';

  # What `services.cage.program` runs on the live ISO: the wizard in ISO mode, then reboot (installed) or the console (quit/failure).
  # sudo is the setuid wrapper (not in a unit's PATH); the live user `nixos` may use it without a password.
  liveSession = pkgs.writeShellScriptBin "pixeldots-live-session" ''
    export PD_ISO=1
    export PD_APPLY=${installIso}/bin/pixeldots-install-iso
    export PD_DISKS_CMD=${disks}/bin/pixeldots-disks
    export PD_LOG=/tmp/pixeldots-install.log
    export XKB_DEFAULT_LAYOUT=us
    export SDL_VIDEODRIVER=wayland
    ${ui}/bin/pixeldots-installer ${data}
    rc=$?
    if [ "$rc" -eq 0 ]; then
      exec /run/wrappers/bin/sudo -n ${pkgs.systemd}/bin/systemctl reboot
    fi
    # cage-tty1 conflicts with getty@tty1, so starting the getty ends this session and shows a console
    exec /run/wrappers/bin/sudo -n ${pkgs.systemd}/bin/systemctl start getty@tty1.service
  '';

  ui = pkgs.stdenv.mkDerivation {
    pname = "pixeldots-installer";
    version = "0.1.0";
    src = ../installer;
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.SDL2 ];
    installPhase = ''
      runHook preInstall
      install -Dm755 pixeldots-installer $out/bin/pixeldots-installer
      runHook postInstall
    '';
    meta.mainProgram = "pixeldots-installer";
  };
in
{
  pixeldots-installer = ui;
  pixeldots-installer-data = data;
  pixeldots-disks = disks;
  pixeldots-install-iso = installIso;
  pixeldots-live-session = liveSession;

  # usage: pixeldots-installer-session <data-dir>   (env PD_APPLY, PD_REPO, ... as set by installer/bootstrap.sh)
  pixeldots-installer-session = pkgs.writeShellScriptBin "pixeldots-installer-session" ''
    exec ${pkgs.cage}/bin/cage -s -- ${ui}/bin/pixeldots-installer "$@"
  '';
}
