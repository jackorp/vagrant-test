#!/bin/bash
# ./test_vagrant.sh [TEST] [USER]
set -x

TEST="$1"
shift

USR="$1"
shift

set -eE

if [ -z "$USR" ]; then
  USR="test"
fi

if [ -z "$TEST" ]; then
  TEST='vagrant ssh -c "let \"n=11*11\" ; echo \${n}"'
fi

trap "vagrant destroy -f" ERR

function as_unprivileged_user() {
  current_pwd=$(pwd)
  sudo -u "$USR" -i bash -c "set -x; cd '${current_pwd}' || exit 1 ; $1"
}

function exec_test_unprivileged() {
  as_unprivileged_user "$TEST" | tee -a /dev/stderr \
    | grep -q 121 && echo '--> Ok'
}

mkdir .vagrant
chown "$USR":"$USR" .vagrant

if as_unprivileged_user "vagrant up"; then
  exec_test_unprivileged

  vagrant destroy -f
  exit 0
else
  exit 1
fi
