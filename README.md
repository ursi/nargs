# How to use

```
nargs <package-name> [nix args]
```
This corresponds to `nix build .#<package-name>` with your arguments applied.

To make a parameterizable derivation, just make it using `pkgs.callPackage`. nargs will use `<package>.override (_: args)` to feed in your arguments. See the test in the flake for an example.
