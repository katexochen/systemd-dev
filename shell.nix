let
  inputs = import ./lon.nix;
in
with import inputs.nixpkgs {};

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

    # command runner for convenience purposes.
    just
  ];
  shellHook = ''
    # SOURCE_DATE_EPOCH=0 is set by nix-shell, however this gets
    # actively rejected by tools generating a secureboot keypair when
    # building an OS image with a fresh systemd.
    unset SOURCE_DATE_EPOCH

    # make mkosi itself available by the Python interpreter. We invoke it via
    # `python -m mkosi`.
    export PYTHONPATH="$(pwd)/mkosi:$PYTHONPATH"

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
  '';
}
