# Overlay adding OpenJDK 26 and 27 built from source on top of nixpkgs.
# Linux only. Nothing in the nixpkgs tree is patched from the outside.
#
# The prebuilt Temurin binaries (temurin-bin-<v> / temurin-jre-bin-<v>), which
# also serve as the bootstrap JDKs, come straight from nixpkgs.
#
# Adding a new version later: drop in an openjdk<n>/ builder (+ its patches)
# and copy a block below.

final: prev:

{
  openjdk26 = final.callPackage ./openjdk26 { };
  openjdk26_headless = final.openjdk26.override { headless = true; };

  jdk26 = final.openjdk26;
  jdk26_headless = final.openjdk26_headless;

  openjdk27 = final.callPackage ./openjdk27 { };
  openjdk27_headless = final.openjdk27.override { headless = true; };

  jdk27 = final.openjdk27;
  jdk27_headless = final.openjdk27_headless;
}
