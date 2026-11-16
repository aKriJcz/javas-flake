# Overlay adding OpenJDK 26 and 27 built from source on top of nixpkgs.
# Linux only. Nothing in the nixpkgs tree is patched from the outside.
#
# Bootstrap chain: Temurin 25 (prebuilt, from nixpkgs) -> openjdk26 -> openjdk27,
# so no Temurin newer than what NixOS stable ships is needed.
#
# The price is that openjdk27 has to build openjdk26 first. To avoid that (or
# to reuse a JDK you already have), choose another boot JDK in an overlay
# applied after this one, e.g. a prebuilt Temurin 26 from nixpkgs unstable:
#
#   final: prev: {
#     openjdk27 = prev.openjdk27.override { jdk-bootstrap = unstable.temurin-bin-26; };
#   }
#
# The headless variants and jdk<v> aliases below follow such an override,
# because they refer to `final`. See "Choosing the bootstrap JDK" in README.md.
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
