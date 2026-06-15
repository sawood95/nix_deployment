{ config, pkgs, lib, ... }:

{
  # Ollama as a systemd service with CUDA acceleration for the RTX 4090.
  # This is the most "NixOS-native" way to run it — the service uses
  # /var/lib/ollama for models and starts automatically.
  services.ollama = {
    enable = true;

    # Select the CUDA-enabled build for NVIDIA acceleration.
    package = pkgs.ollama-cuda;

    # Listen only on localhost by default. Change to "0.0.0.0" if you want
    # other machines on your LAN (or Tailscale) to hit this Ollama instance,
    # and open the firewall port below.
    host = "127.0.0.1";
    port = 11434;

    # If you want the API reachable from your LAN:
    # openFirewall = true;
  };

  # Convenience CLI access for `ollama run ...` from any shell. The service
  # already bundles its own binary, but having `ollama` on $PATH is nice.
  environment.systemPackages = [ config.services.ollama.package ];
}
