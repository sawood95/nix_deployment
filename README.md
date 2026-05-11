# Sagan — NixOS configuration

A flake-based NixOS setup for an RTX 4090 workstation. Manages the system
with `nixpkgs`, and dotfiles / user packages with `home-manager`.

## What it gives you

| Concern | How it's handled |
|---|---|
| Steam + Proton | `programs.steam` with Proton-GE declarative; ProtonPlus GUI for extras |
| AI coding agents | `claude-code` + `codex` from nixpkgs (system-wide) |
| Local LLMs | `services.ollama` with CUDA acceleration, models preloaded |
| Web app dev | `flake.nix` + `direnv` per repo (no Docker daemon needed) |
| Devcontainer fallback | Rootless Podman with Docker-compatible socket |
| Deploy to webserver | `git push` to GitHub → Actions deploys on merge to `dev` |

## Layout

```
.
├── flake.nix                          # entry point, inputs, outputs
├── hosts/sagan/
│   ├── configuration.nix              # bootloader, desktop, users, nix
│   └── hardware-configuration.nix     # REPLACE WITH GENERATED FILE
├── modules/
│   ├── nvidia.nix                     # RTX 4090 drivers
│   ├── gaming.nix                     # Steam, Proton, GameMode
│   ├── dev.nix                        # claude-code, codex, direnv
│   └── ollama.nix                     # Ollama + CUDA + preloaded models
├── home/
│   └── stephen.nix                    # user packages, zsh, kitty, git, ssh
└── devshells/
    ├── web-app-flake.nix              # template flake for your web app repo
    └── web-app.envrc                  # direnv loader for the same
```

## Install (clean machine)

1. Boot the NixOS installer ISO and partition / mount your disks as usual.
2. Generate hardware config:
   ```
   sudo nixos-generate-config --root /mnt
   ```
3. Clone this repo into the new root:
   ```
   sudo nix-shell -p git --run 'git clone <your-fork> /mnt/etc/nixos'
   ```
4. **Replace** `hosts/sagan/hardware-configuration.nix` with the generated
   `/mnt/etc/nixos/hardware-configuration.nix`.
5. Edit `home/stephen.nix` — set your real git name/email.
6. Install:
   ```
   sudo nixos-install --flake /mnt/etc/nixos#sagan
   ```
7. Reboot, log in, and rebuild going forward with:
   ```
   sudo nixos-rebuild switch --flake /etc/nixos#sagan
   ```

## Pull your web app repo

```bash
cd ~/code
git clone git@github.com:you/your-webapp.git
cd your-webapp
```

You have two ways to develop:

### Option A — native devShell (recommended)

Copy the templates into the repo and commit them:

```bash
cp ~/nixos-config/devshells/web-app-flake.nix flake.nix
cp ~/nixos-config/devshells/web-app.envrc .envrc
direnv allow
```

Edit `flake.nix` so the packages list matches your app's actual stack (Node
version, Python, DBs, whatever). From now on, `cd`-ing into the repo
auto-loads a shell with everything pinned. No daemon, no container build.

### Option B — keep the devcontainer

Rootless Podman is set up with `dockerCompat = true`, so the `docker` CLI
and `/var/run/docker.sock` both work — the VS Code Dev Containers extension
will use Podman transparently. Open the repo in VSCodium and "Reopen in
Container" as before. NVIDIA GPU passthrough works via CDI without any of
the SELinux gymnastics you had to do on Fedora — `--device nvidia.com/gpu=all`
just works because `hardware.nvidia-container-toolkit.enable = true` wires
it up declaratively.

## Deploy

Deployment is handled by GitHub Actions: merging to `dev` triggers the
workflow that ships the build to the webserver. From Sagan, you just push
to GitHub.

```bash
cd ~/code/your-webapp
git checkout -b feature/foo
# ...work...
git push origin feature/foo
# open PR, merge to dev, Actions takes it from there
```

First-time setup on Sagan: generate an SSH key and add the public half to
GitHub.

```bash
ssh-keygen -t ed25519 -C "you@example.com"
cat ~/.ssh/id_ed25519.pub  # paste into github.com → Settings → SSH keys
```

The home-manager SSH config already declares `github.com` to use that key.

## Day-to-day

- Rebuild after edits: `sudo nixos-rebuild switch --flake /etc/nixos#sagan`
- Test without activating: `sudo nixos-rebuild test --flake /etc/nixos#sagan`
- Update inputs: `cd /etc/nixos && sudo nix flake update`
- Roll back: pick a previous generation from the boot menu, or
  `sudo nixos-rebuild switch --rollback`
- Pull a new Proton-GE version (when ProtonPlus app isn't fresh enough): just
  use the ProtonPlus GUI — it drops into `~/.steam/root/compatibilitytools.d`
  which Steam already scans (env var is set in `modules/gaming.nix`).

## Notes on the Ollama setup

The service listens on `127.0.0.1:11434` by default and stores models in
`/var/lib/ollama/models`. To check GPU usage:

```bash
ollama ps             # shows PROCESSOR column — should say "100% GPU"
nvtop                 # live GPU monitor
journalctl -u ollama  # service logs, look for "new model will fit in VRAM"
```

If you want VSCodium / Claude Code to talk to your local Ollama, point them
at `http://localhost:11434`.

## Why this shape over `configuration.nix` channels?

- **Flake.lock pins every input.** Same `nixos-rebuild` on day 1 and day 400
  produces the same system. No surprise breakage from a channel auto-update.
- **Home-manager** keeps your zsh/kitty/git/ssh declarative. After your
  Fedora/Omarchy/Bluefin/Pika tour, never re-paste a `.zshrc` again.
- **Modules** split concerns. Want a second host (laptop) sharing some of
  this? Add `hosts/laptop/` and pick which modules it imports.
