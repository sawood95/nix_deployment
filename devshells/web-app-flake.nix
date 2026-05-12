# ============================================================================
# Drop this file into your web app repo as `flake.nix` (alongside a `.envrc`
# containing `use flake` for direnv auto-loading).
#
# What it gives you:
#   * Pinned Node + pnpm + a real Postgres if you want one
#   * `nix develop` (or just `cd` with direnv on) drops you into a shell with
#     every tool on PATH, no Docker daemon, no container build
#   * Same versions on any other NixOS / nix-darwin / Linux-with-Nix machine
#
# Replace the example tools below with whatever your stack actually uses.
# ============================================================================
{
  description = "Web app dev environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # ---- Language toolchain (edit to match your app) ----
              nodejs_22
              pnpm
              # bun
              # python311
              # uv

              # ---- Services you might want (run with: postgres -D ./.data) ----
              postgresql_16
              redis

              # ---- Dev tooling ----
              git
              gh
              nodePackages.prettier
              nodePackages.typescript-language-server
              jq
            ];

            # Runs once per shell entry. Use it for env vars, .env loading, etc.
            shellHook = ''
              export PROJECT_ROOT="$PWD"
              export PGDATA="$PROJECT_ROOT/.data/pg"
              export PGHOST="$PROJECT_ROOT/.data/pg"
              echo "→ Web dev shell ready. Node $(node --version), pnpm $(pnpm --version)"
            '';
          };
        });
    };
}
