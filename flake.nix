{
  description = "Forgefed spec and website";

  inputs.nixpkgs.url = "nixpkgs/nixos-21.05";
  inputs.forgefed = {
    url = "git+https://notabug.org/peers/forgefed.git";
    flake = false;
  };

  outputs = { self, forgefed, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });
    in
    {
      overlay = final: prev: {
        forgefed = with final; stdenv.mkDerivation {
          pname = "forgefed";
          version = builtins.substring 0 8 forgefed.lastModifiedDate;

          nativeBuildInputs = [
            pandoc
          ];

          src = forgefed;

          patchPhase = 
          let
            sed = "${pkgs.gnused}/bin/sed";
          in
          ''
            patchShebangs build.sh
            ${sed} -ie 's/git_branch=.*/git_branch=HEAD/' build.sh
            ${sed} -ie 's/git_commit_id=.*/git_commit_id=${forgefed.rev}/' build.sh
            ${sed} -ie 's/git_commit_id_short=.*/git_commit_id_short=${forgefed.shortRev}/' build.sh
          '';

          buildPhase = ''
            ./build.sh
          '';

          installPhase = ''
            mkdir -p $out
            mv html $out/
          '';
        };
      };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) forgefed;
      });

      defaultPackage = forAllSystems (system: self.packages.${system}.forgefed);

      checks = forAllSystems
        (system: {
          inherit (self.packages.${system}) forgefed;
        });
    };
}
