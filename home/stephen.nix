{ config, pkgs, lib, inputs, username, ... }:

{
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";

  # User-level packages. Things you want available in your shell without
  # being part of the system closure.
  home.packages = with pkgs; [
    # Browsers
    brave
    vivaldi
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

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
    ghostty

    # Fonts (for Ghostty / VSCodium)
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
    settings = {
      "github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
      };
      "webserver" = {
        HostName = "your-server.example.com"; # change me
        User = "deploy"; # change me
        IdentityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  # ==== Zsh + Starship ====
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
      t = "tmux attach || tmux new -s Work";
      # Quick local-LLM shortcuts
      ai = "ollama run qwen2.5-coder:32b";
      aider-local = "aider --model ollama/qwen2.5-coder:32b";
      aider-fast = "aider --model ollama/llama3.1:8b";
      ollama-stop = "sudo systemctl stop ollama";
      ollama-start = "sudo systemctl start ollama";
      ollama-status = "systemctl status ollama";
    };

    initContent = ''
      # Omarchy-style tmux developer layout: editor left, agent top-right,
      # shell bottom-right. Defaults to the local Aider model.
      tdl() {
        local agent="''${1:-aider-local}"
        local session="''${2:-Dev}"

        if tmux has-session -t "$session" 2>/dev/null; then
          tmux attach-session -t "$session"
          return
        fi

        tmux new-session -d -s "$session" -c "$PWD" "''${EDITOR:-vim}"
        tmux split-window -h -t "$session:1" -c "$PWD" "$agent"
        tmux split-window -v -t "$session:1.2" -c "$PWD"
        tmux select-pane -t "$session:1.1"
        tmux attach-session -t "$session"
      }

      # Tmux swarm layout: create N panes running the same command.
      tsl() {
        local panes="''${1:-4}"
        shift || true
        local command="''${*:-aider-local}"
        local session="Swarm"

        if tmux has-session -t "$session" 2>/dev/null; then
          tmux attach-session -t "$session"
          return
        fi

        tmux new-session -d -s "$session" -c "$PWD" "$command"
        for i in $(seq 2 "$panes"); do
          tmux split-window -t "$session:1" -c "$PWD" "$command"
          tmux select-layout -t "$session:1" tiled >/dev/null
        done
        tmux attach-session -t "$session"
      }
    '';
  };

  # ==== Starship prompt ====
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };
  };

  # ==== Ghostty terminal ====
  xdg.configFile."ghostty/config".text = ''
    font-family = JetBrainsMono Nerd Font
    font-size = 12
    window-padding-x = 6
    window-padding-y = 6
    confirm-close-surface = false
  '';

  # ==== Caelestia Shell on Hyprland ====
  programs.caelestia = {
    enable = true;
    # Start Caelestia only from Hyprland so it does not run in GNOME.
    systemd.enable = false;
    cli.enable = true;
  };

  xdg.configFile."hypr/hyprland.conf" = {
    text = ''
      monitor=,preferred,auto,1

      $mod = SUPER
      $terminal = ghostty

      exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      exec-once = caelestia shell -d

      env = XDG_CURRENT_DESKTOP,Hyprland
      env = XDG_SESSION_DESKTOP,Hyprland
      env = XDG_SESSION_TYPE,wayland

      input {
        kb_layout = us
        follow_mouse = 1
        touchpad {
          natural_scroll = true
        }
      }

      general {
        gaps_in = 4
        gaps_out = 8
        border_size = 2
        layout = dwindle
      }

      decoration {
        rounding = 8
      }

      animations {
        enabled = true
      }

      dwindle {
        pseudotile = true
        preserve_split = true
      }

      bind = $mod, Return, exec, $terminal
      bind = $mod, Q, killactive
      bind = $mod, M, exit
      bind = $mod, Space, exec, caelestia shell drawers toggle launcher
      bind = $mod, L, exec, caelestia shell lock lock
      bind = $mod SHIFT, S, exec, caelestia shell picker open
      bind = $mod, F, fullscreen
      bind = $mod, V, togglefloating
      bind = $mod, P, pseudo

      bind = $mod, left, movefocus, l
      bind = $mod, right, movefocus, r
      bind = $mod, up, movefocus, u
      bind = $mod, down, movefocus, d

      bind = $mod SHIFT, left, movewindow, l
      bind = $mod SHIFT, right, movewindow, r
      bind = $mod SHIFT, up, movewindow, u
      bind = $mod SHIFT, down, movewindow, d

      bind = $mod, 1, workspace, 1
      bind = $mod, 2, workspace, 2
      bind = $mod, 3, workspace, 3
      bind = $mod, 4, workspace, 4
      bind = $mod, 5, workspace, 5
      bind = $mod, 6, workspace, 6
      bind = $mod, 7, workspace, 7
      bind = $mod, 8, workspace, 8
      bind = $mod, 9, workspace, 9

      bind = $mod SHIFT, 1, movetoworkspace, 1
      bind = $mod SHIFT, 2, movetoworkspace, 2
      bind = $mod SHIFT, 3, movetoworkspace, 3
      bind = $mod SHIFT, 4, movetoworkspace, 4
      bind = $mod SHIFT, 5, movetoworkspace, 5
      bind = $mod SHIFT, 6, movetoworkspace, 6
      bind = $mod SHIFT, 7, movetoworkspace, 7
      bind = $mod SHIFT, 8, movetoworkspace, 8
      bind = $mod SHIFT, 9, movetoworkspace, 9

      bindm = $mod, mouse:272, movewindow
      bindm = $mod, mouse:273, resizewindow
    '';
  };

  # ==== Tmux ====
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";
    baseIndex = 1;
    historyLimit = 50000;
    escapeTime = 10;
    extraConfig = ''
      # Prefix
      set -g prefix C-Space
      set -g prefix2 C-b
      bind C-Space send-prefix

      # Config and help
      bind q source-file ~/.config/tmux/tmux.conf \; display "Configuration reloaded"
      bind ? list-keys

      # Vi copy mode
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi y send -X copy-selection-and-cancel

      # Pane controls
      bind -n M-Enter split-window -v -c "#{pane_current_path}"
      bind -n M-S-Enter split-window -h -c "#{pane_current_path}"
      bind -n M-Escape kill-pane
      bind h split-window -v -c "#{pane_current_path}"
      bind v split-window -h -c "#{pane_current_path}"
      bind x kill-pane
      bind -n C-M-Left select-pane -L
      bind -n C-M-Right select-pane -R
      bind -n C-M-Up select-pane -U
      bind -n C-M-Down select-pane -D
      bind -n C-M-S-Left resize-pane -L 5
      bind -n C-M-S-Down resize-pane -D 5
      bind -n C-M-S-Up resize-pane -U 5
      bind -n C-M-S-Right resize-pane -R 5

      # Window navigation
      bind r command-prompt -I "#W" "rename-window -- '%%'"
      bind c new-window -c "#{pane_current_path}"
      bind k kill-window
      bind -n M-1 select-window -t 1
      bind -n M-2 select-window -t 2
      bind -n M-3 select-window -t 3
      bind -n M-4 select-window -t 4
      bind -n M-5 select-window -t 5
      bind -n M-6 select-window -t 6
      bind -n M-7 select-window -t 7
      bind -n M-8 select-window -t 8
      bind -n M-9 select-window -t 9
      bind -n M-Left select-window -t -1
      bind -n M-Right select-window -t +1
      bind -n M-S-Left swap-window -t -1 \; select-window -t -1
      bind -n M-S-Right swap-window -t +1 \; select-window -t +1

      # Session controls
      bind R command-prompt -I "#S" "rename-session -- '%%'"
      bind C new-session -c "#{pane_current_path}"
      bind K kill-session
      bind P switch-client -p
      bind N switch-client -n
      bind -n M-Up switch-client -p
      bind -n M-Down switch-client -n

      # General
      set -ag terminal-overrides ",*:RGB"
      setw -g pane-base-index 1
      set -g renumber-windows on
      set -g focus-events on
      set -g set-clipboard on
      set -g allow-passthrough on
      setw -g aggressive-resize on
      set -g detach-on-destroy off
      set -g extended-keys on
      set -g extended-keys-format csi-u

      # Status bar
      set -g status-position top
      set -g status-interval 5
      set -g status-left-length 30
      set -g status-right-length 50
      set -g window-status-separator ""
      set -gw automatic-rename on
      set -gw automatic-rename-format '#{b:pane_current_path}'

      # Theme
      set -g status-style "bg=default,fg=default"
      set -g status-left "#[fg=black,bg=blue,bold] #S #[bg=default] "
      set -g status-right "#[fg=blue]#{?pane_in_mode,COPY ,}#{?client_prefix,PREFIX ,}#{?window_zoomed_flag,ZOOM ,}#[fg=brightblack]#h "
      set -g window-status-format "#[fg=brightblack] #I:#W "
      set -g window-status-current-format "#[fg=blue,bold] #I:#W "
      set -g pane-border-style "fg=brightblack"
      set -g pane-active-border-style "fg=blue"
      set -g message-style "bg=default,fg=blue"
      set -g message-command-style "bg=default,fg=blue"
      set -g mode-style "bg=blue,fg=black"
      setw -g clock-mode-colour blue
    '';
  };

  # Make user-installed fontconfig pick up Nix-installed fonts
  fonts.fontconfig.enable = true;

  # ==== Aider ====
  home.file.".aider.conf.yml".text = ''
    model: ollama/qwen2.5-coder:32b
    weak-model: ollama/llama3.1:8b
  '';

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
