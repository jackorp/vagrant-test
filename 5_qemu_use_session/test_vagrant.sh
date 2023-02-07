#!/bin/bash
# ./test_vagrant.sh [TEST] [USER]
set -x

TEST="$1"
shift

USR="$1"
shift

PRESERVE_ENV="DRIVER,BOX"

EXIT_CODE=0

set -eE

# if [ $TMT_REBOOT_COUNT -lt 1 ]; then
#   tmt-reboot -t 600
# fi

if [ -z "$USR" ]; then
  USR="test"
fi

if [ -z "$TEST" ]; then
  TEST='vagrant ssh -c "let \"n=11*11\" ; echo \${n}"'
fi

#TODO:
# * Reboot at least once (tmt-reboot), ideally only once. Needed for proper libvirt
# * cleanup volumes after test run...
function cleanup() {
  set +eE
  vol_match=$(basename "$(pwd)")
  as_unprivileged_user "vagrant destroy -f"
  as_unprivileged_user "virsh vol-list --pool default | grep \"${vol_match}\" | cut -d' ' -f2 | xargs -rn1 virsh vol-delete --pool default"
  domain=$(as_unprivileged_user "virsh list --name | grep \"${vol_match}\"")
  as_unprivileged_user "echo \"${domain}\" | xargs -rn1 virsh destroy"
  as_unprivileged_user "echo \"${domain}\" | xargs -rn1 virsh undefine"
  set -eE
}

trap cleanup ERR

function as_unprivileged_user() {
  current_pwd=$(pwd)
  sudo --preserve-env="${PRESERVE_ENV}" -u "$USR" -i bash -c "set -x; cd '${current_pwd}' || exit 1 ; $1"
  echo "dbg--> Command '$1' exited with '$?'" 1>&2
}

function exec_test_unprivileged() {
  as_unprivileged_user "$TEST" | tee -a /dev/stderr \
    | grep -q 121 && echo '--> Ok'
  EXIT_CODE=$?
}

mkdir .vagrant
chown "$USR":"$USR" .vagrant

if as_unprivileged_user "vagrant up"; then
  exec_test_unprivileged

  cleanup
  exit $EXIT_CODE
else
  cleanup
  echo "--> 'vagrant up' Failed"
  exit 1
fi
