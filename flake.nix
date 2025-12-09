{
  description = "dangreco/schema2nix environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    files.url = "github:/mightyiam/files";
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.git-hooks-nix.flakeModule
        inputs.files.flakeModules.default
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          self',
          pkgs,
          config,
          ...
        }:
        {
          packages.default = pkgs.ocamlPackages.buildDunePackage {
            pname = "schema2nix";
            version = "0.1.0";
            src = ./.;

            buildInputs = with pkgs.ocamlPackages; [
              cmdliner
            ];

            meta = {
              description = "Convert schema to Nix";
              license = pkgs.lib.licenses.mit;
            };
          };

          packages.docker = pkgs.dockerTools.buildLayeredImage {
            name = "schema2nix";
            tag = "latest";

            contents = [ self'.packages.default ];

            config = {
              Entrypoint = [ "${self'.packages.default}/bin/schema2nix" ];
            };
          };

          files.files = [
            {
              path_ = ".zed/settings.json";
              drv = pkgs.writers.writeJSON "settings.json" {
                lsp.ocamllsp.binary.path = "${pkgs.ocamlPackages.ocaml-lsp}/bin/ocamllsp";
                languages.OCaml.formatter.external = {
                  command = "${pkgs.ocamlPackages.ocamlformat}/bin/ocamlformat";
                  arguments = [
                    "--enable-outside-detected-project"
                    "--name"
                    "{buffer_path}"
                    "-"
                  ];
                };
              };
            }
          ];

          pre-commit.settings.hooks = {
            nixfmt.enable = true;
            dune-fmt.enable = true;
            yamlfmt.enable = true;
            yamllint.enable = true;
          };

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [

              nixd
              nixfmt

              git
              pinact
              go-task

              yamlfmt
              yamllint

              # tools
              ocamlPackages.ocaml
              ocamlPackages.dune_3
              ocamlPackages.findlib
              ocamlPackages.utop
              ocamlPackages.odoc
              ocamlPackages.ocaml-lsp
              ocamlPackages.ocamlformat
            ];

            shellHook = ''
              ${config.files.writer.drv}/bin/write-files || true
              ${config.pre-commit.shellHook}
            '';
          };
        };
    };
}
