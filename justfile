distribution := "fedora"
tools_distribution := "fedora"

base_args := "--distribution=" + distribution + " --tools-tree-distribution=" + tools_distribution
mkosi := "python -m mkosi"

sd := env_var('SYSTEMD_SRC')

call := just_executable() + " --justfile=" + justfile()

init-mkosi:
  {{call}} genkey
  {{call}} box -- meson setup build
  {{call}} build-mkosi

setup: init-mkosi

mkosi *OPTIONS:
  cd {{sd}} && {{mkosi}} {{base_args}} {{OPTIONS}}

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

clean:
  rm -rf {{sd}}/build

reinstall-vm-pkg: build
  {{call}} mkosi -R && {{call}} mkosi ssh -- dnf upgrade --disablerepo="*" --assumeyes "/work/build/*.rpm"

unittest:
  {{call}} box -- meson test -C build --print-errorlogs -q

list-tests:
  {{call}} box -- meson introspect build --tests

integration-test NAME *OPTS:
  {{call}} box -- meson test -C build --setup=integration -v {{NAME}} {{OPTS}}
