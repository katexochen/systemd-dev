# systemd-dev

Useful scripts to manage a systemd-based dev environment on NixOS.

This is essentially a [`just`-based](https://just.systems/man/en/) that invokes `mkosi` and has a few
quality-of-life things on top.

Right now this only supports distros that [`mkosi`](https://mkosi.systemd.io/), so this isn't fully
NixOS-native (yet).

## Prerequisites

For this to work properly, your host-system **must** use an overlay-based `/etc`, i.e.
[`system.etc.overlay.enable = true;`](https://search.nixos.org/options?channel=25.11&show=system.etc.overlay.enable&query=etc.overlay).

## Quick start

Enter a `nix-shell` with all relevant tools and environment variables set:
```
$ nix-shell
```

Clone `mkosi` and `systemd` into this directory, compile sources and build a Fedora
image:

```
[nix-shell:~/systemd-dev]$ just init-mkosi
```

Boot the image in a VM:

```
[nix-shell:~/systemd-dev]$ just vm
```

This command leaves you in a shell of that VM. Further sessions can be
opened by SSHing into the VM:

```
[nix-shell:~/systemd-dev]$ just mkosi ssh
```

Generally, it's possible to call the locally checked out `mkosi` with
`just mkosi <ARGS>`.

Instead of booting a fully-fledged VM, it's also possible to boot an nspawn
container like this:

```
[nix-shell:~/systemd-dev]$ just boot
```

Running unit-tests:

```
[nix-shell:~/systemd-dev]$ just unit-test
```

Please note that some of these tests are environment-sensitive and don't work yet, e.g. because `/var/tmp` as
temporary directory is expected.

A single integration test can be executed like this:

```
[nix-shell:~/systemd-dev]$ just integration-test TEST-01-BASIC
```

For further information on how to hack on `systemd`, please refer to their
[hacking guide](https://systemd.io/HACKING/) and the
[guide on systemd's test-suite](https://github.com/systemd/systemd/blob/main/test/integration-tests/README.md).

## Notes

### Changes to the `systemd` tree

A bunch of scripts (e.g. `mkosi.sync`) are executed before a fully configured tools-tree exists.
Hence, it relies on tools on the host-side to exist, including `/bin/bash`. For now,
when we clone, the shebangs are replaced with `/usr/bin/env bash`.

Whether to upstream or using a different workaround is undecided so far.

### Patches in `mkosi`

All patches necessary to function were upstreamed 🎉

### Vision

I think that the notion of a tools-tree is something that NixOS was designed for from the beginning. So the next thing I'm considering
to try is to implement support for a Nix/NixOS-based tools-tree in `mkosi`. Using `nixpkgs` as source would also make it even simpler
to build dev images with dependencies of `systemd` being patched.

A non-trivial, hard-to-achieve, long-term goal is to get to a point where systemd is in a position to run its test-suite against
NixOS during development, making updates for us way simpler. This is a long way to go however and includes making it possible to
build & boot a (minimal) NixOS without any downstream patches.
