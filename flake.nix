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
    applicationCreate = pkgs.writeShellApplication {
      name = "application-create";
      runtimeInputs = with pkgs; [coreutils gh gitMinimal gnugrep jq nix];
      text = builtins.readFile ./application-create.sh;
    };
    actionCheck = pkgs.runCommand "deployment-action-check" {nativeBuildInputs = [pkgs.action-validator];} ''
      mkdir -p actions/{deploy,setup-deployment,setup-nix}
      cp ${./.github/actions/deploy/action.yml} actions/deploy/action.yml
      cp ${./.github/actions/setup-deployment/action.yml} actions/setup-deployment/action.yml
      cp ${./.github/actions/setup-nix/action.yml} actions/setup-nix/action.yml
      action-validator actions/*/action.yml
      touch "$out"
    '';
    preCommitCheck = git-hooks.lib.${system}.run {
      package = pkgs.prek;
      src = ./.;
      hooks = {
        actionlint.enable = true;
        alejandra.enable = true;
        check-added-large-files.enable = true;
        check-merge-conflicts.enable = true;
        end-of-file-fixer.enable = true;
        shellcheck.enable = true;
        trim-trailing-whitespace.enable = true;
      };
    };
  in {
    packages.${system} = {
      default = applicationCreate;
      inherit applicationCreate;
    };
    apps.${system} = {
      default = {
        type = "app";
        program = "${applicationCreate}/bin/application-create";
      };
      applicationCreate = {
        type = "app";
        program = "${applicationCreate}/bin/application-create";
      };
    };
    checks.${system} = {
      action = actionCheck;
      application-create = applicationCreate;
      pre-commit = preCommitCheck;
    };
    formatter.${system} = pkgs.alejandra;
    devShells.${system}.default = pkgs.mkShell {
      packages = preCommitCheck.enabledPackages ++ [pkgs.action-validator];
      inherit (preCommitCheck) shellHook;
    };
  };
}
