#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

IMAGE_NAME=$1
DIRACOS_INSTALLER=$2

# Build an inner script that runs as a non-root user (required so that
# chmod 500 on $HOME actually blocks writes; root ignores permission bits).
tmp_inner=$(mktemp)
trap 'rm -f "${tmp_inner}"' EXIT
cat > "${tmp_inner}" <<EOF
#!/usr/bin/env bash
set -euxo pipefail
workdir=\$(mktemp -d)
export HOME="\${workdir}/home"
mkdir "\${HOME}"
chmod -R 500 "\${HOME}"
cd "\${workdir}"
bash /diracos-repo/${DIRACOS_INSTALLER}
set -u
source diracos/diracosrc
pytest -v /diracos-repo/tests/test_import.py
bash /diracos-repo/tests/test_cli.sh
EOF
chmod +x "${tmp_inner}"

exec docker run --rm --privileged \
  -v "${PWD}":/diracos-repo \
  -v "${tmp_inner}":/tmp/inner.sh:ro \
  "${IMAGE_NAME}" bash -c '
    set -euxo pipefail
    useradd -m -u 1001 tester
    runuser -u tester -- /tmp/inner.sh
  '
