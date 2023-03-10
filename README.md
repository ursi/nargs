# How to use

```
nargs build [package-name] [nix args]
nargs develop [package-name] [nix args]
```

To make a parameterizable derivation, build it using `pkgs.callPackage`. nargs will use `<package>.override (_: args)` to feed in your command line arguments. See the tests in the flake for examples.
