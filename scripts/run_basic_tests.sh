#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

IMAGE_NAME=$1
DIRACOS_INSTALLER=$2

# Run as a non-root user so that chmod 500 on $HOME actually blocks writes
# (root ignores permission bits, which would mask regressions like
# DIRACGrid/DIRACOS2#174).
exec docker run --rm --user 1001:1001 -v "${PWD}":/diracos-repo "${IMAGE_NAME}" bash -c '
  set -euxo pipefail
  workdir=$(mktemp -d)
  export HOME="${workdir}/home"
  mkdir "${HOME}"
  chmod -R 500 "${HOME}"
  cd "${workdir}"
  bash /diracos-repo/'"${DIRACOS_INSTALLER}"'
  set -u
  source diracos/diracosrc
  pytest -v /diracos-repo/tests/test_import.py
  bash /diracos-repo/tests/test_cli.sh
'
