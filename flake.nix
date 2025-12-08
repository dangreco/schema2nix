{
  description = "dangreco/schema2nix environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    files.url = "github:/mightyiam/files";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      imports = [ inputs.files.flakeModules.default ];
      perSystem =
        {
          pkgs,
          config,
          ...
        }:
        {
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

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              nil
              nixd
              nixfmt

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
            '';
          };
        };
    };
}
