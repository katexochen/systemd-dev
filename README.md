# systemd-dev

Useful scripts to manage a systemd-based dev environment on NixOS.

This is essentially a [`just`-based](https://just.systems/man/en/) wrapper that invokes `mkosi` and has a few
quality-of-life things on top.

Right now this only supports distros that [`mkosi`](https://mkosi.systemd.io/) supports, so this isn't fully
NixOS-native (yet).

The tooling (this repo) is kept separate from the sources: `systemd` and `mkosi` are checked out elsewhere
and pull the dev shell in via [`direnv`](https://direnv.net/). This keeps the source trees clean and lets you
run several `systemd` worktrees in parallel, all sharing the same tools.

## Prerequisites

- Your host-system **must** use an overlay-based `/etc`, i.e.
  [`system.etc.overlay.enable = true;`](https://search.nixos.org/options?channel=25.11&show=system.etc.overlay.enable&query=etc.overlay).
- [`direnv`](https://direnv.net/), ideally with [`nix-direnv`](https://github.com/nix-community/nix-direnv).

## Layout

`systemd` and `mkosi` are checked out at the same level, next to this repo:

```
code/
├── systemd-dev/      # this repo (tooling: shell.nix, justfile)
├── systemd/          # systemd source
└── mkosi/            # mkosi source
```

Either source may be a plain checkout or a worktree layout; the `mkosi` location is auto-detected
(`systemd.envrc` picks the `main` worktree when the source is set up that way). An accepted worktree
layout looks like this:

```
code/
├── systemd-dev/      # this repo (tooling: shell.nix, justfile)
├── systemd/
│   ├── main/         # systemd source (worktree)
│   └── <feature>/    # further worktrees
└── mkosi/
    └── main/         # mkosi source (worktree)
```

## Setup

Check out the sources at the same level as this repo:

```
$ git -C .. clone https://github.com/systemd/systemd
$ git -C .. clone https://github.com/systemd/mkosi
```

Link the tracked `systemd.envrc` into the `systemd` checkout as `.envrc`, then allow it:

```
$ ln -s ../systemd-dev/systemd.envrc ../systemd/.envrc
$ direnv allow ../systemd
```

For a worktree layout the `.envrc` symlink lives in each worktree instead:

```
$ ln -s ../../systemd-dev/systemd.envrc ../systemd/main/.envrc
$ direnv allow ../systemd/main
```

Use a worktree manager that copies the file when a new worktree is created.

Entering the `systemd` directory now loads the dev shell (all tools and environment variables)
automatically, and the `just` recipes operate on that checkout.

## Quick start

From the `systemd` checkout, compile the sources and build a Fedora image:

```
[systemd]$ just init-mkosi
```

Boot the image in a VM:

```
[systemd]$ just vm
```

This leaves you in a shell of that VM. Further sessions can be opened by SSHing into it:

```
[systemd]$ just mkosi ssh
```

Generally, it's possible to call the locally checked out `mkosi` with `just mkosi <ARGS>`.

Instead of booting a fully-fledged VM, it's also possible to boot an nspawn container:

```
[systemd]$ just boot
```

Running unit-tests:

```
[systemd]$ just unittest
```

Please note that some of these tests are environment-sensitive and don't work yet, e.g. because `/var/tmp` as
temporary directory is expected.

A single integration test can be executed like this:

```
[systemd]$ just integration-test TEST-01-BASIC
```

For further information on how to hack on `systemd`, please refer to their
[hacking guide](https://systemd.io/HACKING/) and the
[guide on systemd's test-suite](https://github.com/systemd/systemd/blob/main/test/integration-tests/README.md).

## Notes

### Patches in `mkosi`

All patches necessary to function were upstreamed 🎉

### Vision

I think that the notion of a tools-tree is something that NixOS was designed for from the beginning. So the next thing I'm considering
to try is to implement support for a Nix/NixOS-based tools-tree in `mkosi`. Using `nixpkgs` as source would also make it even simpler
to build dev images with dependencies of `systemd` being patched.

A non-trivial, hard-to-achieve, long-term goal is to get to a point where systemd is in a position to run its test-suite against
NixOS during development, making updates for us way simpler. This is a long way to go however and includes making it possible to
build & boot a (minimal) NixOS without any downstream patches.
