{ lib, 
pkgs, 
stdenv, 
config,
dpkg, 
fetchurl, 
makeWrapper, 
autoPatchelfHook, 
libxml2, 
zlib, 
gcc, 
glibc, 
libcxx, 
libgcc, 
audit, 
libgcrypt,
...
}:

with lib; let
  cfg = config.my.programs.bitdefender;
  version = "7.5.0.200217";
in {
  options.my.programs.bitdefender = {
    enable = mkEnableOption "enable bitdefender endpoint security tools";
  };

  config = mkIf cfg.enable (let 
    bitdefender = stdenv.mkDerivation rec {
      pname = "bitdefender-endpoint-security-tools";
      inherit version;

      openssl = pkgs.openssl_1_1; # Specify the correct version here

      src = fetchurl {
        url = "file:///home/buggy/bitdefender/bitdefender-security-tools_${version}_amd64.deb";
        sha256 = "a8ba0225f2ee342e1f0ed41772eb0d53c8a3caffe419138fe0a2b029171a4a58";
      };

      nativeBuildInputs = [
        dpkg
        makeWrapper
        autoPatchelfHook
      ];

      buildInputs = [
        stdenv.cc.cc.lib
        libxml2
        openssl
        zlib
        gcc
        glibc
        libcxx
        libgcc
        audit
        libgcrypt
      ];

      preBuild = ''
        export NIXPKGS_ALLOW_INSECURE=1
      '';

      unpackPhase = ''
        dpkg-deb -x $src $out
        dpkg-deb -e $src $out/DEBIAN
      '';

      # Commented out installPhase as it's not necessary
      /*
      installPhase = ''
        mkdir -p $out
        cp -r $out/opt $out/
      '';
      */

      postFixup = ''
        # Manually patch libraries and ELF executables ONLY, EXCLUDING /bin
        for libfile in $out/opt/bitdefender-security-tools/lib/*.so*; do
          echo "Processing $libfile"
          if file "$libfile" | grep -q "ELF"; then
            echo "...Patching"
            patchelf --set-rpath "${lib.makeLibraryPath buildInputs}:$out/lib:$out/lib64:$out/opt/bitdefender-security-tools/lib" "$libfile"
          fi
        done

        # Manually set RPATH for binaries and libraries with missing dependencies
        for bin in $out/opt/bitdefender-security-tools/bin/* $out/opt/bitdefender-security-tools/lib/*.so*; do
          if file "$bin" | grep -q "ELF"; then
            echo "Setting RPATH for $bin"
            patchelf --set-rpath "${lib.makeLibraryPath buildInputs}:$out/lib:$out/lib64:$out/opt/bitdefender-security-tools/lib" "$bin"
          fi
        done
      '';

      meta = with lib; {
        description = "Bitdefender Endpoint Security Tools for Linux";
        homepage = "https://www.bitdefender.com/business/enterprise-products/endpoint-security.html";
        platforms = [ "x86_64-linux" ];
        maintainers = with maintainers; [ "Buggy" ];
      };
    }; in {
    environment.systemPackages = [ bitdefender ];
  });
}
