# Installer UI (C++/SDL2) and a session wrapper that runs it inside the `cage` kiosk compositor.
# apply.sh and data/ are NOT copied into the store: the bootstrapper runs them from the git checkout,
# because the generated system config points programs.material.repoPath at that checkout.
{ pkgs }:

let
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

  # usage: pixeldots-installer-session <data-dir>   (env PD_APPLY, PD_REPO, ... as set by installer/bootstrap.sh)
  pixeldots-installer-session = pkgs.writeShellScriptBin "pixeldots-installer-session" ''
    exec ${pkgs.cage}/bin/cage -s -- ${ui}/bin/pixeldots-installer "$@"
  '';
}
