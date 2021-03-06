{
  description = "phobos devenv flake";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.uefi-run.url = "github:yakuri354/uefi-run";

  outputs = { self, nixpkgs, flake-utils, uefi-run }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        {
          devShell =
            pkgs.mkShell {
              buildInputs = with pkgs; [
                nixpkgs-fmt
                nasm
                uefi-run.defaultPackage.${system}
                buildPackages.buildPackages.qemu
                clang
                zig
                zls
              ];
                
              shellHook = ''
                export OVMF_PATH="${pkgs.OVMF.fd}/FV/OVMF.fd"
              '';

            };
        }
      );
}
