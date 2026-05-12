{ config, pkgs, lib, ... }:

{
  # Modern graphics stack (replaces hardware.opengl on 24.11+)
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam, Proton, Wine need 32-bit support
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    # RTX 4090 (Ada) works well with the proprietary driver.
    # The open kernel modules are now production-ready for Turing+ but the
    # proprietary blob still tends to perform a touch better for gaming.
    open = false;

    # Suspend/resume reliability
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    nvidiaSettings = true;

    # Use the stable production driver branch
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # NVIDIA + Wayland: gives GNOME/Hyprland a smooth ride on recent drivers
  environment.sessionVariables = {
    # Hint apps to use the NVIDIA GBM backend
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # Fixes some apps under Wayland that misbehave with EGL
    LIBVA_DRIVER_NAME = "nvidia";
  };
}
