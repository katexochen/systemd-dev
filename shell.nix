let
  inputs = import ./lon.nix;
in
with import inputs.nixpkgs { };

let
  # systemd's external C dependencies, exposed so clangd can resolve their headers.
  clangdDeps = systemd.buildInputs;
in
mkShell {
  packages = [
    # for mkosi itself
    python3

    # runtime dependencies of mkosi.
    # must be inside the nix-shell, i.e. an executable in
    # a store-path entry to be picked up by the mkiosi sandbox.
    git
    curl
    dnf5
    util-linux
    systemd
    clang-tools
    lon
    valgrind
    libselinux

    # command runner for convenience purposes.
    just
  ];

  nativeBuildInputs = [ pkg-config ];
  buildInputs = clangdDeps;

  shellHook = ''
    # SOURCE_DATE_EPOCH=0 is set by nix-shell, however this gets
    # actively rejected by tools generating a secureboot keypair when
    # building an OS image with a fresh systemd.
    unset SOURCE_DATE_EPOCH

    # NixOS sets TZDIR=/etc/zoneinfo, which links into the nix store.
    # 'mkosi box' leaks TZDIR into the box, but the symlink doesn't resolve there.
    # systemd hard-codes /usr/share/zoneinfo, which exists in the box,
    # but glibc resolves via TZDIR, fails, falls back to UTC, causing test failures.
    unset TZDIR

    export MANPAGER=less

    # make mkosi itself available by the Python interpreter. We invoke it via
    # `python -m mkosi`.
    export PYTHONPATH="''${MKOSI_SRC:-$(pwd)/mkosi}''${PYTHONPATH:+:$PYTHONPATH}"

    # Otherwise output from some build processes is hardly readable on
    # a light terminal.
    export SYSTEMD_TINT_BACKGROUND=0

    # Needed for the build-sandbox.
    export LD_LIBRARY_PATH="${lib.makeLibraryPath [ libseccomp ]}"

    # HACK: TMPDIR in a nix-shell is `/tmp/nix-shell-<hash>/build-top/`. Inside that,
    # we have a unique prefix from tempfile.TemporaryDirectory and inside that, a socket
    # with a UUIDv4 id for collision avoidance is used. The resulting path is too long
    # for a socket.
    # We simply use `/tmp/nix-shell-<hash>` (without the `build-top`-part) to work around
    # that problem for now.
    export TMPDIR="$(realpath "$TMPDIR/../")"

    export JUST_JUSTFILE=${toString ./justfile}

    # The compile database is generated inside the (Fedora) box and references
    # /usr/include, which is absent on the host. Put the nix headers of systemd's
    # dependencies on CPATH (clang honours it) so clangd resolves them.
    export CPATH=${lib.makeSearchPathOutput "dev" "include" clangdDeps}$(
      for _m in $(pkg-config --list-all 2>/dev/null | cut -d' ' -f1); do
        pkg-config --cflags-only-I "$_m" 2>/dev/null
      done | tr ' ' '\n' | sed -n 's/^-I/:/p' | sort -u | tr -d '\n'
    )
  '';
}
