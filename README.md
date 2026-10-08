# Nix flake with multiple OpenJDK versions

⚠️ This is entirely vibe-coded flake for now, assembled as a quick hack. I am currently using OpenJDK 26 on NixOS 25.11 with no issues so far. YMMV ⚠️

## Packages

Linux only (`x86_64-linux`, `aarch64-linux`).

| Version | Built from source | Prebuilt Temurin |
|---------|-------------------|------------------|
| 26 | `openjdk26`, `openjdk26_headless` (aliases `jdk26`, `jdk26_headless`) | `temurin-bin-26`, `temurin-jre-bin-26` |
| 27 | `openjdk27`, `openjdk27_headless` (aliases `jdk27`, `jdk27_headless`) | `temurin-bin-27`, `temurin-jre-bin-27` |

`packages.default` and the dev shell use `openjdk27`. The overlay is exported as `overlays.default`.
