{ config, pkgs, lib, inputs, username, hostname, ... }:

{
  # ==== Boot ====
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ==== Networking ====
  networking.hostName = hostname;
  networking.networkmanager.enable = true;
  # Open firewall for SSH and Steam Remote Play (Steam module also opens its own)
  networking.firewall.enable = true;

  # ==== Locale / Time ====
  time.timeZone = "America/New_York"; # adjust to taste
  i18n.defaultLocale = "en_US.UTF-8";

  # ==== Desktop ====
  # GNOME on Wayland is a solid default; swap for plasma6 / hyprland if preferred.
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xserver.xkb.layout = "us";

  # ==== Audio ====
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;
  };

  # ==== User ====
  users.users.${username} = {
    isNormalUser = true;
    description = "Stephen";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "podman" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  # ==== Nix settings ====
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    # Use the official Nix binary cache plus some useful extras
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Allow unfree packages (Steam, NVIDIA drivers, etc.)
  nixpkgs.config.allowUnfree = true;

  # ==== System packages (kept minimal — user-level stuff lives in home.nix) ====
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    pciutils
    usbutils
    htop
  ];

  # ==== SSH (for pushing to your webserver, GitHub, etc.) ====
  # GNOME enables gcr-ssh-agent by default; don't also install the OpenSSH
  # agent system-wide or NixOS will reject the configuration.
  services.openssh = {
    enable = false; # flip to true if you want to SSH _into_ Sagan
    settings.PasswordAuthentication = false;
  };

  # ==== Containers — rootless Podman ====
  virtualisation.containers.enable = true;
  virtualisation.podman = {
    enable = true;

    # Expose a Docker-compatible socket and `docker` CLI alias. This is what
    # makes VS Code Dev Containers, testcontainers, docker-compose, and any
    # other tool that hardcodes "docker" Just Work without modification.
    dockerCompat = true;
    dockerSocket.enable = true;

    # Resolve image short names without prompting (e.g. `podman run nginx`
    # finds docker.io/library/nginx automatically).
    defaultNetwork.settings.dns_enabled = true;
  };

  # CDI-based NVIDIA passthrough for rootless containers. This is the modern
  # replacement for the old --gpus flag approach and works without SELinux
  # workarounds on NixOS (no `chcon` / udev hacks needed — unlike Fedora).
  hardware.nvidia-container-toolkit.enable = true;

  # User-namespace allocation for rootless containers. NixOS handles this
  # automatically when the user is created, but being explicit doesn't hurt.
  # `podman info` should show "rootless: true" for the stephen user.

  # First version of NixOS this config targets. DO NOT bump after install
  # without reading the release notes.
  system.stateVersion = "25.05";
}
