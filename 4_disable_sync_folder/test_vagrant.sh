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

function exec_test_as_user() {
  sudo -u "$1" -i bash -c "set -x; $TEST" | tee -a /dev/stderr \
    | grep -q 121 && echo '--> Ok'
}

function as_unprivileged_user() {
  sudo -u "$1" -i bash -c "vagrant up"
}

if as_unprivileged_user "$USR"; then
  exec_test_as_user "$USR"

  vagrant destroy -f
  exit 0
else
  exit 1
fi
