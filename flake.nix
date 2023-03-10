{ inputs =
    { nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      utils.url = "github:ursi/flake-utils/8";
    };

  outputs = inputs:
    with builtins;
    inputs.utils.apply-systems { inherit inputs; }
      ({ pkgs, ... }:
         let l = p.lib; p = pkgs; in
         rec
         { packages =
             { default =
                 p.writeShellScriptBin "nargs"
                   ''
                   if [[ "$1" == build || "$1" == develop ]]; then
                     if [[ "$1" == build ]]; then
                       type=packages
                     else
                       type=devShells
                     fi

                     if [[ "$2" == -* || "$2" == "" ]]; then
                       package=default
                       argstart=2
                     else
                       package="$2"
                       argstart=3
                     fi

                     tmp=$(mktemp)

                     echo "with builtins;
                     { ... }@args:
                       let
                         package =
                           (getFlake \"path:$PWD\")
                             ."''${type}"
                             .\''${currentSystem}
                             .\"$package\";
                       in
                       if package?override
                       then package.override (_: args)
                       else package" > $tmp

                     nix "$1" -f $tmp "''${@:$argstart}"
                     rm $tmp
                   else
                     echo "nargs build [package-name] [nix args]"
                     echo "nargs develop [package-name] [nix args]"
                   fi
                   '';

               test =
                 let
                   test = { n }: p.runCommand "test" {} "echo ${toString n} > $out";
                 in
                 p.callPackage test { n = 0; };
             };

           devShells.test =
             let
               test = { n }:
                 p.mkShell
                   { buildInputs =
                       [ (p.writeShellScriptBin "test-script" "echo ${toString n}") ];
                   };
             in
             p.callPackage test { n = 0; };

           apps.test =
             { type = "app";

               program =
                 let nargs = "${packages.default}/bin/nargs"; in
                 (p.writeShellScript "test-script"
                    ''
                    if [[ $(cat $(${nargs} build test --no-link --print-out-paths --arg n 1)) == 1
                       && $(${nargs} develop test --arg n 1 --command test-script) == 1
                       ]]
                    then
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
