# Overlay adding Java 26 (and, later, further versions) on top of nixpkgs.
# Linux only. Nothing in the nixpkgs tree is patched from the outside.
#
# Two flavours are provided per JDK version:
#   * temurin-bin-<v> / temurin-jre-bin-<v>  — prebuilt Adoptium binaries
#     (built by re-using nixpkgs' temurin base builder with our own source
#      data, so nothing needs to exist in the nixpkgs tree).
#   * openjdk<v> / openjdk<v>_headless       — built from source by our own
#     self-contained ./openjdk/openjdk<v>.nix builder.
#
# Adding a new version later: drop in temurin-<n>-sources.json and an
# openjdk/openjdk<n>.nix builder (+ its patches), then copy the blocks below.

final: prev:

let
  inherit (final) lib stdenv;

  ## --- Temurin prebuilt binaries -------------------------------------------

  temurinSources = lib.importJSON ./temurin-26-sources.json;
  temurinDir = final.path + "/pkgs/development/compilers/temurin-bin";

  # nixpkgs' base builder is `sourcePerArch -> (deps -> derivation)`, so we can
  # call it directly with our own source data — no in-tree files needed.
  mkTemurin =
    packageType:
    let
      variant = if stdenv.hostPlatform.isMusl then "alpine-linux" else "linux";
      sourcePerArch = temurinSources.${variant}.${packageType};
    in
    final.callPackage (import (temurinDir + "/jdk-linux-base.nix") { inherit sourcePerArch; }) { };
in
{
  temurin-bin-26 = mkTemurin "jdk";
  temurin-jre-bin-26 = mkTemurin "jre";

  ## --- OpenJDK built from source -------------------------------------------

  openjdk26 = final.callPackage ./openjdk26 { };
  openjdk26_headless = final.openjdk26.override { headless = true; };

  jdk26 = final.openjdk26;
  jdk26_headless = final.openjdk26_headless;
}
