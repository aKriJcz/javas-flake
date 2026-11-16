# Nix flake with multiple OpenJDK versions

⚠️ This is entirely vibe-coded flake for now, assembled as a quick hack. I am currently using OpenJDK 26 on NixOS 25.11 with no issues so far. YMMV ⚠️

## Why

nixpkgs builds OpenJDK from source only for LTS releases (currently up to 25). The newer feature releases are still waiting in open pull requests ([openjdk26](https://github.com/NixOS/nixpkgs/pull/506259), [openjdk27](https://github.com/NixOS/nixpkgs/pull/565775)), so this flake provides them in the meantime. Once they land in nixpkgs, the corresponding builder here becomes redundant.

## Packages

Linux only (`x86_64-linux`, `aarch64-linux`).

| Version | Built from source (this flake) | Prebuilt Temurin (re-exported from nixpkgs) |
|---------|--------------------------------|---------------------------------------------|
| 26 | `openjdk26`, `openjdk26_headless` (aliases `jdk26`, `jdk26_headless`) | `temurin-bin-26`, `temurin-jre-bin-26` |
| 27 | `openjdk27`, `openjdk27_headless` (aliases `jdk27`, `jdk27_headless`) | `temurin-bin-27`, `temurin-jre-bin-27` |

The source builders are trimmed copies of nixpkgs' `openjdk/generic.nix` with the same patches where they still apply. Each one is bootstrapped with the Temurin binary of the previous release from nixpkgs (26 with Temurin 25, 27 with Temurin 26).

`packages.default` and the dev shell use `openjdk27`.

## Usage

```sh
nix build github:aKriJcz/javas-flake#openjdk27
nix develop github:aKriJcz/javas-flake   # shell with JDK 27 and JAVA_HOME set
```

The overlay is exported as `overlays.default`. It adds only the source builds, so it needs a nixpkgs recent enough to contain `temurin-bin-26`:

```nix
{
  inputs.javas.url = "github:aKriJcz/javas-flake";

  # in a NixOS configuration:
  nixpkgs.overlays = [ inputs.javas.overlays.default ];
  environment.systemPackages = [ pkgs.jdk27 ];
}
```
