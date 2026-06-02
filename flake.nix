{
  description = "Java packages (OpenJDK 26 and beyond) as a nixpkgs overlay — Linux only";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = f: lib.genAttrs systems (system: f system);

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
    in
    {
      # The overlay is the reusable bit — add it to your own nixpkgs to get
      # jdk26 / openjdk26 / temurin-bin-26 etc.
      overlays.default = import ./overlay.nix;

      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          openjdk26 = pkgs.openjdk26;
          openjdk26_headless = pkgs.openjdk26_headless;
          jdk26 = pkgs.jdk26;
          jdk26_headless = pkgs.jdk26_headless;
          temurin-bin-26 = pkgs.temurin-bin-26;
          temurin-jre-bin-26 = pkgs.temurin-jre-bin-26;
          default = pkgs.openjdk26;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          jdk = pkgs.openjdk26;
        in
        {
          default = pkgs.mkShell {
            packages = [ jdk ];
            shellHook = ''
              export JAVA_HOME=${jdk}/lib/openjdk
            '';
          };
        }
      );
    };
}
