{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    miryoku-zmk = {
      url = "github:manna-harbour/miryoku_zmk";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      zmk-nix,
      miryoku-zmk,
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        rec {
          default = firmware;

          firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
            name = "firmware";

            src = pkgs.symlinkJoin {
              name = "zmk-config-klor";
              paths = [
                (nixpkgs.lib.sourceFilesBySuffices self [
                  ".board"
                  ".cmake"
                  ".conf"
                  ".defconfig"
                  ".dts"
                  ".dtsi"
                  ".json"
                  ".keymap"
                  ".overlay"
                  ".shield"
                  ".yml"
                  "_defconfig"
                ])
                (pkgs.runCommandLocal "miryoku-zmk" { } ''
                  mkdir -p $out
                  ln -s ${miryoku-zmk} $out/miryoku_zmk
                '')
              ];
            };

            board = "nice_nano//zmk";
            # board = "nrfmicro/nrf52840/zmk";
            shield = "klor_%PART%";
            # enableZmkStudio = true;
            snippets = [ ];

            zephyrDepsHash = "sha256-NioLnxuiI3gpgB2wAQUg/V/L/yMBlaob2wZtOdVoHDI=";

            meta = {
              description = "ZMK firmware";
              license = nixpkgs.lib.licenses.mit;
              platforms = nixpkgs.lib.platforms.all;
            };
          };

          flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };
          update = zmk-nix.packages.${system}.update;
        }
      );

      devShells = forAllSystems (system: {
        default = zmk-nix.devShells.${system}.default;
      });
    };
}
