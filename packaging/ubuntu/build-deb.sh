#!/bin/bash
# Construit le .deb PloufPlouf pour Ubuntu via Docker.
# À lancer depuis la racine du projet (tirage_equipes).
# Prérequis: Docker installé.

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

IMAGE_NAME=ploufplouf-deb-builder
OUT_DIR="${SCRIPT_DIR}/out"
mkdir -p "${OUT_DIR}"

echo "==> Construction de l'image Docker (Ubuntu 22.04 + Flutter)..."
docker build -t "${IMAGE_NAME}" -f packaging/ubuntu/Dockerfile packaging/ubuntu/

echo "==> Build de l'app et création du .deb dans le conteneur..."
docker run --rm \
  -v "${PROJECT_ROOT}:/src" \
  -w /src \
  "${IMAGE_NAME}" \
  bash packaging/ubuntu/build-in-docker.sh

echo ""
echo "==> Paquet .deb généré: packaging/ubuntu/out/ploufplouf_1.0.1_amd64.deb"
echo "    À installer sur Ubuntu avec: sudo dpkg -i ploufplouf_1.0.0_amd64.deb"
echo "    (sudo apt-get install -f si des dépendances manquent)"
