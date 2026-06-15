{ config, pkgs, lib, ... }:

{
  # GNOME remains the dependable fallback session, while Hyprland is available
  # from GDM's session chooser for the Caelestia shell workflow.
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Caelestia expects these desktop services in lightweight compositor sessions.
  # GNOME already provides equivalents, but Hyprland needs them wired.
  services.power-profiles-daemon.enable = lib.mkDefault true;
  services.accounts-daemon.enable = lib.mkDefault true;
  services.geoclue2.enable = lib.mkDefault true;
  security.polkit.enable = lib.mkDefault true;
}
