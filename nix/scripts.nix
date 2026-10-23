{ pkgs }:

let
  mk =
    name: runtimeInputs: file:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = builtins.readFile file;
    };
in
{
  # Wallpaper + Material You colour state (wraps matugen).
  material-theme = mk "material-theme" (with pkgs; [
    coreutils
    findutils
    gnugrep
    jq
    matugen
    dconf
  ]) ../scripts/material-theme.sh;

  # Region / full / window screenshots to ~/Pictures/Screenshots + clipboard.
  material-screenshot = mk "material-screenshot" (with pkgs; [
    coreutils
    grim
    slurp
    jq
    wl-clipboard
    libnotify
  ]) ../scripts/material-screenshot.sh;
}
