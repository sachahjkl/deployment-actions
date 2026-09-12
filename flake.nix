{
  description = "Reusable GitHub workflows for applications";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2605";
    git-hooks = {
      url = "https://flakehub.com/f/cachix/git-hooks.nix/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    git-hooks,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    preCommitCheck = git-hooks.lib.${system}.run {
      package = pkgs.prek;
      src = ./.;
      hooks = {
        actionlint.enable = true;
        alejandra.enable = true;
        check-added-large-files.enable = true;
        check-merge-conflicts.enable = true;
        end-of-file-fixer.enable = true;
        trim-trailing-whitespace.enable = true;
      };
    };
  in {
    checks.${system}.pre-commit = preCommitCheck;
    formatter.${system} = pkgs.alejandra;
    devShells.${system}.default = pkgs.mkShell {
      packages = preCommitCheck.enabledPackages;
      inherit (preCommitCheck) shellHook;
    };
  };
}
