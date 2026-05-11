{ config, pkgs, lib, ... }:

{
  # ==== Steam ====
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    # Optional Steam Deck-style compositor session you can pick from the
    # login screen for a "big picture mode" experience.
    gamescopeSession.enable = true;

    # Ship Proton-GE declaratively. ProtonPlus (below) can still install more
    # versions imperatively into ~/.steam/root/compatibilitytools.d if you
    # want bleeding-edge GE builds Nixpkgs hasn't caught up to yet.
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  # Steam needs several unfree packages. Our configuration.nix has
  # `nixpkgs.config.allowUnfree = true` so this is already permitted, but
  # if you prefer the stricter predicate form, this is the list to use:
  #
  #   nixpkgs.config.allowUnfreePredicate = pkg:
  #     builtins.elem (lib.getName pkg) [
  #       "steam" "steam-unwrapped" "steam-original" "steam-run"
  #     ];

  # Where Steam looks for extra Proton versions installed by ProtonPlus /
  # protonup-qt. Setting this means imperative installs Just Work.
  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };

  # GameMode boosts CPU performance for games that opt in
  programs.gamemode.enable = true;

  # System-wide gaming tools
  environment.systemPackages = with pkgs; [
    protonplus    # GUI manager for Proton / Wine versions
    protontricks  # tweak per-game Proton prefixes
    mangohud      # FPS / frame-time overlay
    gamescope     # micro-compositor for Steam
  ];

  # Some games and Proton versions hit the default file-descriptor ceiling
  systemd.extraConfig = "DefaultLimitNOFILE=1048576";
  systemd.user.extraConfig = "DefaultLimitNOFILE=1048576";
}
