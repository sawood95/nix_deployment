{ config, pkgs, lib, ... }:

{
  # System-level dev packages. Per-language toolchains generally belong in
  # per-project devShells (see devshells/web.nix) rather than installed
  # globally, so they're pinned with your repo.
  environment.systemPackages = with pkgs; [
    # AI coding agents — both in nixpkgs unstable
    claude-code
    codex

    # VCS + GitHub
    git
    git-lfs
    gh

    # General
    jq
    ripgrep
    fd
    bat
    eza
    fzf
    tmux
    htop
    btop
    nvtopPackages.full # GPU usage monitor

    # Editor (your call — keep one)
    vscodium

    # Container tooling. Podman provides the `docker` CLI alias via
    # virtualisation.podman.dockerCompat, so existing scripts and the
    # Dev Containers extension keep working without changes.
    podman-compose # python reimplementation of docker-compose
    podman-tui # terminal UI for managing containers/pods
    dive # inspect image layers
  ];

  # direnv + nix-direnv: auto-load a project's flake devShell when you cd in.
  # This is the magic that makes flake-based dev environments feel as easy as
  # devcontainers — without the daemon overhead.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = false;
  };
}
