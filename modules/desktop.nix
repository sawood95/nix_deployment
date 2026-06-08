{ config, pkgs, lib, ... }:

{
  # GNOME remains the dependable default session, while MangoWC is available
  # from GDM's session chooser for a lighter Wayland compositor workflow.
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  programs.mangowc.enable = true;

  # DankMaterialShell expects these desktop services in lightweight compositor
  # sessions. GNOME already provides equivalents, but MangoWC needs them wired.
  services.power-profiles-daemon.enable = lib.mkDefault true;
  services.accounts-daemon.enable = lib.mkDefault true;
  services.geoclue2.enable = lib.mkDefault true;
  security.polkit.enable = lib.mkDefault true;
}
