distribution := "fedora"
tools_distribution := "fedora"

base_args := "--distribution=" + distribution + " --tools-tree-distribution=" + tools_distribution
mkosi := "python -m mkosi"
git := "git"

mkosi_repo := "git@github.com:systemd/mkosi"
mkosi_branch := "main"

systemd_repo := "git@github.com:systemd/systemd"
systemd_branch := "main"

call := just_executable() + " --justfile=" + justfile()

clone:
  #! /usr/bin/env bash
  set -euo pipefail
  if [ ! -d mkosi ]; then
    {{git}} clone {{mkosi_repo}} --branch {{mkosi_branch}}
  fi
  if [ ! -d systemd ]; then
    {{git}} clone {{systemd_repo}} --branch {{systemd_branch}}
    for f in mkosi.{clangd,clean,sync,images/build/mkosi.conf.d/centos-fedora/mkosi.prepare}; do
      sed -i'' -e 's,/bin/bash,/usr/bin/env bash,' systemd/mkosi/"$f"
    done
  fi

[private]
ensure-cloned:
  #! /usr/bin/env bash
  set -euo pipefail
  if [ ! -d mkosi ] || [ ! -d systemd ]; then
    echo -e "\e[31msystemd and/or mkosi checkout are missing. Run 'just clone' first!\e[0m]"
    exit 1
  fi

init-mkosi: ensure-cloned
  {{call}} genkey
  {{call}} box -- meson setup build
  {{call}} build-mkosi

setup: clone init-mkosi

mkosi *OPTIONS:
  cd systemd && {{mkosi}} {{base_args}} {{OPTIONS}}

genkey:
  {{call}} mkosi -f genkey

vm:
  {{call}} mkosi vm

boot:
  {{call}} mkosi boot

box *OPTIONS:
  {{call}} mkosi -f box {{OPTIONS}}

build:
  {{call}} box -- meson compile -C build

build-mkosi:
  {{call}} box -- meson compile -C build mkosi

clean-full:
  sudo rm -rf mkosi systemd

reinstall-vm-pkg: build
  {{call}} mkosi -R && {{call}} mkosi ssh -- dnf upgrade --disablerepo="*" --assumeyes "/work/build/*.rpm"

unittest:
  {{call}} box -- meson test -C build --print-errorlogs -q

list-tests:
  {{call}} box -- meson introspect build --tests

integration-test NAME *OPTS:
  {{call}} box -- meson test -C build --setup=integration -v {{NAME}} {{OPTS}}
