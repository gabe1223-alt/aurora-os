#!/usr/bin/env bash
# Aurora OS – one-command build.
#   ./build.sh            full build
#   ./build.sh --clean    remove the old build container first, then build
#   CONTINUE=1 ./build.sh resume a failed build (keeps the container)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIGEN_REPO="${PIGEN_REPO:-https://github.com/RPI-Distro/pi-gen.git}"
PIGEN_BRANCH="${PIGEN_BRANCH:-arm64}"      # 64-bit branch; must match RELEASE in ./config
WORK="${HERE}/build/pi-gen"
OUT="${HERE}/out"

for tool in git docker openssl; do
  command -v "$tool" >/dev/null || { echo "Missing required tool: $tool" >&2; exit 1; }
done

if [[ "${1:-}" == "--clean" ]]; then
  echo ">> Removing old pi-gen container (if any)"
  docker rm -v pigen_work >/dev/null 2>&1 || true
  rm -rf "${WORK}/work" "${WORK}/deploy"
fi

mkdir -p "${HERE}/build" "${OUT}"
if [[ ! -d "${WORK}/.git" ]]; then
  echo ">> Cloning pi-gen (${PIGEN_BRANCH})"
  git clone --branch "${PIGEN_BRANCH}" "${PIGEN_REPO}" "${WORK}"
fi

echo ">> Installing the Aurora stage into pi-gen"
rm -rf "${WORK}/stage-aurora"
cp -a "${HERE}/stage-aurora" "${WORK}/stage-aurora"
find "${WORK}/stage-aurora" -name '*.sh' -exec chmod +x {} +
# Don't export the intermediate "lite" image from stage2.
touch "${WORK}/stage2/SKIP_IMAGES"

echo ">> Writing build config (with a random throw-away setup password)"
{
  cat "${HERE}/config"
  printf "FIRST_USER_PASS='%s'\n" "$(openssl rand -hex 16)"
} > "${WORK}/config"

cd "${WORK}"
export PRESERVE_CONTAINER=1
if [[ "${CONTINUE:-0}" == "1" ]]; then export CONTINUE=1; fi

echo ">> Starting Docker build (this takes 1-3 hours the first time)"
./build-docker.sh

echo ">> Collecting results"
shopt -s nullglob
cp -v deploy/*.img.xz deploy/*.info "${OUT}/" 2>/dev/null || true
ls -lh "${OUT}"
echo
echo "Done. Flash the .img.xz in ${OUT} with Raspberry Pi Imager (Use custom) or balenaEtcher."
echo "IMPORTANT: leave Imager's 'OS customisation' OFF - Aurora has its own first-boot wizard."
