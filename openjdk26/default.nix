# Self-contained OpenJDK 26 builder (Linux only).
#
# This is a trimmed copy of nixpkgs' pkgs/development/compilers/openjdk/
# generic.nix, specialised to feature version 26: the source is fetched
# directly here, the patch list is concrete (no version-dispatch), and only the
# code paths that apply to JDK 26 on Linux are kept. Nothing in the nixpkgs tree
# is patched from the outside.
#
# Source data mirrors pkgs/development/compilers/openjdk/26/source.json from the
# upstream "openjdk26: init" change.
{
  lib,
  stdenv,
  fetchFromGitHub,

  buildPackages,
  autoPatchelfHook,
  pkg-config,
  autoconf,
  unzip,
  ensureNewerSourcesForZipFilesHook,
  pandoc,

  cpio,
  file,
  which,
  zip,
  zlib,
  cups,
  freetype,
  alsa-lib,
  libjpeg,
  giflib,
  libpng,
  lcms2,
  libx11,
  libice,
  libxext,
  libxrender,
  libxtst,
  libxt,
  libxi,
  libxinerama,
  libxcursor,
  libxrandr,
  fontconfig,

  setJavaClassPath,
  versionCheckHook,

  # JDK 26 is bootstrapped with the Temurin 25 binary from nixpkgs.
  temurin-bin-25,
  jdk-bootstrap ? temurin-bin-25.__spliced.buildBuild or temurin-bin-25,

  headless ? false,

  enableGtk ? true,
  gtk3,
  glib,
}:

let
  version = "26-ga";

  src = fetchFromGitHub {
    owner = "openjdk";
    repo = "jdk26u";
    rev = "refs/tags/jdk-26-ga";
    hash = "sha256-kR++u1rVL1SkAa9l657Qz/m+eONJsvmoag8ZpX1moug=";
  };

  jdk-bootstrap' = jdk-bootstrap.override {
    # When building a headless jdk, also bootstrap it with a headless jdk.
    gtkSupport = !headless;
  };
in

stdenv.mkDerivation (finalAttrs: {
  pname = "openjdk" + lib.optionalString headless "-headless";
  inherit version src;

  outputs = [ "out" ];

  patches = [
    ./patches/read-truststore-from-env-jdk25.patch
    ./patches/make-4.4.1.patch
    ./patches/ignore-LegalNoticeFilePlugin-jdk18.patch
  ]
  ++ lib.optionals (!headless && enableGtk) [
    ./patches/swing-use-gtk-jdk13.patch
  ];

  strictDeps = true;

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  nativeBuildInputs = [
    autoPatchelfHook
    pkg-config
    unzip
    zip
    which
    zlib
    autoconf
    ensureNewerSourcesForZipFilesHook
    pandoc
  ];

  buildInputs = [
    cpio
    file
    cups
    freetype
    alsa-lib
    libjpeg
    giflib
    libx11
    libice
    libxext
    libxrender
    libxtst
    libxt
    libxi
    libxinerama
    libxcursor
    libxrandr
    fontconfig
    libpng
    zlib
    lcms2
  ]
  ++ lib.optionals (!headless && enableGtk) [
    gtk3
    glib
  ];

  propagatedBuildInputs = [ setJavaClassPath ];

  nativeInstallCheckInputs = [ versionCheckHook ];

  # JDK's build system attempts to specifically detect and special-case WSL,
  # so pass the correct platform names explicitly.
  configurePlatforms = [
    "build"
    "host"
  ];

  # https://openjdk.org/groups/build/doc/building.html
  configureFlags = [
    "READELF=${stdenv.cc.targetPrefix}readelf"
    "AR=${stdenv.cc.targetPrefix}ar"
    "STRIP=${stdenv.cc.targetPrefix}strip"
    "NM=${stdenv.cc.targetPrefix}nm"
    "OBJDUMP=${stdenv.cc.targetPrefix}objdump"
    "OBJCOPY=${stdenv.cc.targetPrefix}objcopy"
    "--with-boot-jdk=${jdk-bootstrap'.home}"
    "--enable-unlimited-crypto"
    "--with-native-debug-symbols=internal"
    "--with-stdc++lib=dynamic"
    "--with-zlib=system"
    "--with-giflib=system"
    "--with-version-string=${version}"
    "--with-vendor-version-string=(nix)"
    "--with-libjpeg=system"
    "--with-libpng=system"
    "--with-lcms=system"
  ]
  ++ lib.optionals stdenv.cc.isClang [
    "--with-toolchain-type=clang"
    "--with-extra-cxxflags=-xc++"
  ]
  ++ lib.optional headless "--enable-headless-only";

  buildFlags = [ "images" ];

  separateDebugInfo = true;
  __structuredAttrs = true;

  # -j is rejected by the build system ("use 'make JOBS=N'"); it still builds in
  # parallel via --with-jobs below.
  enableParallelBuilding = false;

  preConfigure = ''
    configureFlags+=("--with-jobs=''${NIX_BUILD_CORES}")
  '';

  env = {
    NIX_CFLAGS_COMPILE = "-Wno-error";

    NIX_LDFLAGS = lib.concatStringsSep " " (
      lib.optionals (!headless) [
        "-lfontconfig"
        "-lcups"
        "-lXinerama"
        "-lXrandr"
        "-lmagic"
      ]
      ++ lib.optionals (!headless && enableGtk) [
        "-lgtk-3"
        "-lgio-2.0"
      ]
    );
  };

  versionCheckProgram = "${placeholder "out"}/bin/java";

  # Fails with "No rule to make target 'y'."
  doCheck = false;
  doInstallCheck = true;

  postPatch = ''
    chmod +x configure
    patchShebangs --build configure

    chmod +x make/scripts/*.{template,sh,pl}
    patchShebangs --build make/scripts

    # Increase the javadoc heap (the upstream nixpkgs patch no longer applies
    # cleanly to the jdk26u tree, so do it as a substitution instead).
    substituteInPlace make/Docs.gmk \
      --replace-fail \
        '-Dextlink.spec.version=$$(VERSION_SPECIFICATION)' \
        '-Dextlink.spec.version=$$(VERSION_SPECIFICATION) -Xmx1G'
  '';

  installPhase = ''
    mkdir -p $out/lib
    mv build/*/images/jdk $out/lib/openjdk

    # Remove some broken manpages.
    rm -rf $out/lib/openjdk/man/ja*

    # Mirror some stuff in top-level.
    mkdir -p $out/share
    ln -s $out/lib/openjdk/bin $out/bin
    ln -s $out/lib/openjdk/include $out/include
    ln -s $out/lib/openjdk/man $out/share/man

    # IDEs use the provided src.zip to navigate the Java codebase.
    ln -s $out/lib/openjdk/lib/src.zip $out/lib/src.zip

    # jni.h expects jni_md.h to be in the header search path.
    ln -s $out/include/linux/*_md.h $out/include/

    # Remove crap from the installation.
    rm -rf $out/lib/openjdk/demo
    ${lib.optionalString headless ''
      rm $out/lib/openjdk/lib/{libjsound,libfontmanager}.so
    ''}
  '';

  # Set JAVA_HOME automatically.
  preFixup = ''
    mkdir -p $out/nix-support
    cat <<EOF > $out/nix-support/setup-hook
    if [ -z "\''${JAVA_HOME-}" ]; then export JAVA_HOME=$out/lib/openjdk; fi
    EOF
  '';

  # Patch the output in a separate auto-patchelf execution to avoid cyclic
  # references being flagged as errors.
  dontAutoPatchelf = true;
  postFixup = ''
    autoPatchelf -- $out
  '';

  disallowedReferences = [ jdk-bootstrap' ];

  passthru = {
    home = "${finalAttrs.finalPackage}/lib/openjdk";
    inherit jdk-bootstrap gtk3;
  };

  meta = {
    description = "Open-source Java Development Kit (version 26)";
    homepage = "https://openjdk.java.net/";
    license = lib.licenses.gpl2Only;
    mainProgram = "java";
    platforms = [
      "i686-linux"
      "x86_64-linux"
      "aarch64-linux"
      "armv7l-linux"
      "armv6l-linux"
      "powerpc64le-linux"
      "riscv64-linux"
    ];
  };
})
