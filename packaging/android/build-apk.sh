#!/bin/bash
# Construit l'APK PloufPlouf pour Android (release).
# À lancer depuis la racine du projet (tirage_equipes).
# Prérequis : Flutter SDK, Android SDK (ANDROID_HOME ou flutter doctor).

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

OUT_DIR="${SCRIPT_DIR}/out"
mkdir -p "${OUT_DIR}"

echo "==> flutter pub get"
flutter pub get

echo "==> flutter build apk --release"
flutter build apk --release

APK_SRC="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "${APK_SRC}" ]; then
  echo "Erreur: APK non trouvé après le build (${APK_SRC})."
  exit 1
fi

# Copie avec nom versionné pour distribution
VER=$(grep '^version:' pubspec.yaml | sed 's/version: *\([^+]*\).*/\1/' | tr -d ' ')
APK_DEST="${OUT_DIR}/ploufplouf_${VER}.apk"
cp -f "${APK_SRC}" "${APK_DEST}"
echo ""
echo "==> APK généré : ${APK_DEST}"
echo "    À installer sur un smartphone Android (transfert USB ou lien de téléchargement)."
echo "    Activer « Sources inconnues » si nécessaire pour installer."
