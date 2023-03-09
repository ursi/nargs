{ inputs =
    { nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      utils.url = "github:ursi/flake-utils/8";
    };

  outputs = inputs:
    with builtins;
    inputs.utils.apply-systems { inherit inputs; }
      ({ pkgs, ... }:
         let
           l = p.lib; p = pkgs;
           test = { n }: p.runCommand "test" {} "echo ${toString n} > $out";
         in
         rec
         { packages =
             { default =
                 p.writeShellScriptBin "nargs"
                   ''
                   tmp=$(mktemp)

                   echo "with builtins;
                   { ... }@args:
                     (getFlake \"path:$PWD\")
                       .packages
                       .\''${currentSystem}
                       .\"$1\"
                       .override (_: args)" > $tmp

                   nix build -f $tmp "''${@:2}"
                   rm $tmp
                   '';

               test = p.callPackage test { n = 0; };
             };

           apps.test =
             { type = "app";

               program =
                 (p.writeShellScript "test-script"
                    ''
                    ${packages.default}/bin/nargs test -o test --arg n 1
                    if [[ $(cat test) == 1 ]]; then
                      echo test passed
                    else
                      echo test failed
                    fi
                    ''
                 ).outPath;
             };
         }
      );
}
