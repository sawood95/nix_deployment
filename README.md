# Sagan — NixOS configuration

A flake-based NixOS setup for an RTX 4090 workstation. Manages the system
with `nixpkgs`, and dotfiles / user packages with `home-manager`.

Repo: <https://github.com/sawood95/nix_deployment>

## Bootstrap from zero

The exact sequence to go from a freshly-downloaded NixOS ISO to a working
Sagan with your webapp cloned. No browser needed on the new machine until
the very end.

**Before you start:** write down `github.com/sawood95/nix_deployment`. That
is the only thing you need to remember off the new machine.

1. **Boot the NixOS installer ISO** from a USB stick. Get to a root shell.

2. **Partition and mount** your disks the usual way. Mount the root
   partition at `/mnt` and the EFI partition at `/mnt/boot`.

3. **Generate hardware config** for this machine:
   ```bash
   sudo nixos-generate-config --root /mnt
   ```
   This writes `/mnt/etc/nixos/hardware-configuration.nix` and a default
   `configuration.nix` you'll be replacing.

4. **Save the generated hardware config aside, then clone this repo into
   place:**
   ```bash
   cp /mnt/etc/nixos/hardware-configuration.nix /tmp/hw.nix
   sudo rm -rf /mnt/etc/nixos
   nix-shell -p git --run \
     'git clone https://github.com/sawood95/nix_deployment /mnt/etc/nixos'
   sudo cp /tmp/hw.nix /mnt/etc/nixos/hosts/sagan/hardware-configuration.nix
   ```

5. **Edit the placeholders.** At minimum, set your real git name/email:
   ```bash
   nano /mnt/etc/nixos/home/stephen.nix
   ```
   Also double-check `time.timeZone` in `hosts/sagan/configuration.nix`.

6. **Install:**
   ```bash
   sudo nixos-install --flake /mnt/etc/nixos#sagan
   ```
   Set a root password when prompted, then `reboot`.

7. **First boot.** Log in as `stephen`. Open kitty.

8. **Authenticate to GitHub** using device flow — no browser needed on
   Sagan, you'll use your phone:
   ```bash
   gh auth login
   ```
   Pick: GitHub.com → HTTPS → Login with a web browser. It prints a code
   like `XXXX-XXXX`. On your phone, open <https://github.com/login/device>,
   sign in, type the code. The CLI on Sagan is now authenticated.

   When it asks whether to also set up an SSH key — say yes. It generates
   `~/.ssh/id_ed25519`, uploads the public half to your GitHub account, and
   configures git to use SSH for github.com URLs.

9. **Clone your webapp:**
   ```bash
   mkdir -p ~/code && cd ~/code
   gh repo clone you/your-webapp
   cd your-webapp
   ```

10. **Set up the dev shell** (one-time, if you haven't committed `flake.nix`
    and `.envrc` to the webapp repo yet):
    ```bash
    cp /etc/nixos/devshells/web-app-flake.nix flake.nix
    cp /etc/nixos/devshells/web-app.envrc .envrc
    direnv allow
    ```
    Edit `flake.nix` so the packages match your actual stack, commit both
    files, push.

Done. From here on, `cd`-ing into the webapp auto-loads the dev shell, and
merging to `dev` triggers your GitHub Actions deploy.

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

## Install

See [Bootstrap from zero](#bootstrap-from-zero) above. After the system is
up, edits to the config are applied with:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#sagan
```

## Web app development modes

Once the repo is cloned (bootstrap step 9), you have two ways to develop:

### Option A — native devShell (recommended)

Copy the templates into the repo and commit them:

```bash
cp /etc/nixos/devshells/web-app-flake.nix flake.nix
cp /etc/nixos/devshells/web-app.envrc .envrc
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

## Testing this repo before install

If you are editing from a standalone Nix install before this repo is checked
out as `/etc/nixos`, use a `path:` flake reference so Nix sees untracked files:

```bash
nix flake check path:$PWD
```

That command is expected to fail while
`hosts/sagan/hardware-configuration.nix` is still the placeholder, because
there is no real `/` filesystem declaration yet. After generating and copying
the real hardware config, run:

```bash
git add -A
nix flake check
```

To check the rest of the module graph before hardware is available, evaluate
with a temporary root filesystem overlay:

```bash
nix eval --impure --expr 'let
  flake = builtins.getFlake "path:${builtins.getEnv "PWD"}";
  cfg = flake.nixosConfigurations.sagan.extendModules {
    modules = [ ({ ... }: { fileSystems."/" = { device = "none"; fsType = "tmpfs"; }; }) ];
  };
in cfg.config.system.build.toplevel.drvPath'
```

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
