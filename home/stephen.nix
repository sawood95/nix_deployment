{ config, pkgs, lib, username, ... }:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.05";

  # User-level packages. Things you want available in your shell without
  # being part of the system closure.
  home.packages = with pkgs; [
    # Browsers
    brave
    vivaldi

    # Comms / media
    discord
    obs-studio

    # Productivity
    obsidian

    # Dev utilities (user-scoped versions)
    lazygit
    delta # nicer git diffs
    just # task runner
    fastfetch # just to be cool :)

    # Fonts (for kitty / VSCodium)
    nerd-fonts.jetbrains-mono
  ];

  # ==== Git ====
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Stephen Wood"; # change me
        email = "swood95@gmail.com"; # change me
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta.navigate = true;
      merge.conflictstyle = "diff3";
      alias = {
        st = "status -sb";
        lg = "log --oneline --graph --decorate -20";
        co = "checkout";
      };
    };
  };

  # ==== SSH ====
  # Define the webserver here so `ssh webserver` and `git push web` Just Work.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com" = {
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
      };
      "webserver" = {
        hostname = "your-server.example.com"; # change me
        user = "deploy"; # change me
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  # ==== Zsh + Powerlevel10k ====
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    shellAliases = {
      ll = "eza -lah --git";
      ls = "eza";
      cat = "bat --paper-color=auto";
      gs = "git status -sb";
      gp = "git push";
      # Quick local-LLM shortcuts
      ai = "ollama run qwen2.5-coder:32b";
    };

    initContent = ''
      # Powerlevel10k instant prompt
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
      # Source your existing p10k config (you can also manage it via home-manager
      # by adding a file to home.file."./.p10k.zsh".source).
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
    '';

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];
  };

  # ==== Kitty terminal ====
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    settings = {
      enable_audio_bell = false;
      window_padding_width = 6;
      cursor_blink_interval = 0;
      scrollback_lines = 10000;
      # Wayland-friendly defaults
      linux_display_server = "auto";
    };
  };

  # Make user-installed fontconfig pick up Nix-installed fonts
  fonts.fontconfig.enable = true;

  # ==== VSCodium config snippet ====
  # If you want to manage VSCodium settings declaratively, uncomment:
  # programs.vscode = {
  #   enable = true;
  #   package = pkgs.vscodium;
  #   profiles.default.extensions = with pkgs.vscode-extensions; [
  #     mkhl.direnv
  #     jnoortheen.nix-ide
  #     bbenoist.nix
  #   ];
  # };

  # ==== direnv (user-side) ====
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
