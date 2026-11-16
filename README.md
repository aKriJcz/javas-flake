# Nix flake with multiple OpenJDK versions

⚠️ This is entirely vibe-coded flake for now, assembled as a quick hack. I am currently using OpenJDK 26 on NixOS 25.11 with no issues so far. YMMV ⚠️

## Why

nixpkgs builds OpenJDK from source only for LTS releases (currently up to 25). The newer feature releases are still waiting in open pull requests ([openjdk26](https://github.com/NixOS/nixpkgs/pull/506259), [openjdk27](https://github.com/NixOS/nixpkgs/pull/565775)), so this flake provides them in the meantime. Once they land in nixpkgs, the corresponding builder here becomes redundant.

## Packages

Linux only (`x86_64-linux`, `aarch64-linux`).

| Version | Packages |
|---------|----------|
| 26 | `openjdk26`, `openjdk26_headless` (aliases `jdk26`, `jdk26_headless`) |
| 27 | `openjdk27`, `openjdk27_headless` (aliases `jdk27`, `jdk27_headless`) |

The source builders are trimmed copies of nixpkgs' `openjdk/generic.nix` with the same patches where they still apply. The flake is pinned to the NixOS stable release (`nixos-26.05`), whose newest prebuilt Temurin is 25. A JDK can only be bootstrapped by the previous release or by itself, so the chain is Temurin 25 (from nixpkgs) → `openjdk26` → `openjdk27`. Building `openjdk27` therefore builds `openjdk26` first, and no Temurin binaries are shipped by this flake.

`packages.default` and the dev shell use `openjdk27`.

## Usage

```sh
nix build github:aKriJcz/javas-flake#openjdk27
nix develop github:aKriJcz/javas-flake   # shell with JDK 27 and JAVA_HOME set
```

The overlay is exported as `overlays.default`. It needs only `temurin-bin-25` from the nixpkgs it is applied to, so it works on NixOS 26.05:

```nix
{
  inputs.javas.url = "github:aKriJcz/javas-flake";

  # in a NixOS configuration:
  nixpkgs.overlays = [ inputs.javas.overlays.default ];
  environment.systemPackages = [ pkgs.jdk27 ];
}
```

### Choosing the bootstrap JDK

The defaults stay on NixOS stable and download a single prebuilt JDK (Temurin 25), at the price of building `openjdk26` before `openjdk27`. You may prefer a different trade-off:

- **Faster builds:** bootstrap `openjdk27` with a prebuilt JDK 26 or 27 and skip the `openjdk26` build entirely.
- **A JDK you already have:** reuse one that is already in your store or binary cache, e.g. from another nixpkgs revision or another vendor (Zulu, Corretto, …).
- **A newer nixpkgs:** once your nixpkgs ships a suitable Temurin, use it directly.

Each builder takes a `jdk-bootstrap` argument, so the boot JDK can be replaced with `.override`. It can be any JDK package with a `home` attribute, as long as its version is one the build accepts: 25 or 26 for `openjdk26`, 26 or 27 for `openjdk27`.

For example, to skip building `openjdk26` and bootstrap `openjdk27` with a prebuilt Temurin 26 from nixpkgs unstable:

```nix
nixpkgs.overlays = [
  inputs.javas.overlays.default
  (final: prev: {
    openjdk27 = prev.openjdk27.override {
      jdk-bootstrap = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.temurin-bin-26;
    };
  })
];
```

`openjdk27_headless` and the `jdk27*` aliases follow that override. For a headless build the boot JDK is switched to its headless variant too when it supports that (the builders here and nixpkgs' Temurin do); any other JDK is used as given.
