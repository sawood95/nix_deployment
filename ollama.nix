{ config, pkgs, lib, ... }:

{
  # Ollama as a systemd service with CUDA acceleration for the RTX 4090.
  # This is the most "NixOS-native" way to run it — the service uses
  # /var/lib/ollama for models and starts automatically.
  services.ollama = {
    enable = true;

    # acceleration = "cuda" pulls the ollama-cuda build automatically.
    acceleration = "cuda";

    # Listen only on localhost by default. Change to "0.0.0.0" if you want
    # other machines on your LAN (or Tailscale) to hit this Ollama instance,
    # and open the firewall port below.
    host = "127.0.0.1";
    port = 11434;

    # Pre-pull these models on first activation. Pick whatever you actually
    # use day-to-day; a 4090's 24 GB of VRAM comfortably runs 70B-ish at
    # Q4_0 quantization or larger 32B models with full precision.
    loadModels = [
      "qwen2.5-coder:32b"   # solid local coding model
      "llama3.1:8b"         # lightweight general-purpose
      "nomic-embed-text"    # embeddings for RAG / editor plugins
    ];

    # If you want the API reachable from your LAN:
    # openFirewall = true;
  };

  # Convenience CLI access for `ollama run ...` from any shell. The service
  # already bundles its own binary, but having `ollama` on $PATH is nice.
  environment.systemPackages = [ pkgs.ollama-cuda ];
}
