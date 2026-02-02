#!/bin/bash
# Exécuté à l'intérieur du conteneur Docker. Construit l'app et crée le .deb.
# Le répertoire courant est la racine du projet (monté en /src).

set -e
cd /src

# Nettoyer le build Linux pour éviter les chemins absolus du host (CMake cache)
echo "==> Nettoyage du cache build Linux (chemins host vs conteneur)"
rm -rf build/linux

echo "==> flutter pub get"
flutter pub get

echo "==> flutter build linux --release"
flutter build linux --release

BUNDLE="build/linux/x64/release/bundle"
if [ ! -f "${BUNDLE}/tirage_equipes" ]; then
  echo "Erreur: bundle non trouvé."
  exit 1
fi

PKG_NAME=ploufplouf
PKG_VER=1.0.1
DEB_DIR="packaging/ubuntu/deb_root"
OUT_DIR="packaging/ubuntu/out"

rm -rf "${DEB_DIR}"
mkdir -p "${DEB_DIR}/opt/ploufplouf"
mkdir -p "${DEB_DIR}/usr/bin"
mkdir -p "${DEB_DIR}/usr/share/applications"
mkdir -p "${DEB_DIR}/DEBIAN"
mkdir -p "${OUT_DIR}"

echo "==> Copie du bundle vers ${DEB_DIR}/opt/ploufplouf"
cp -a "${BUNDLE}"/* "${DEB_DIR}/opt/ploufplouf/"

echo "==> Création du lanceur /usr/bin/ploufplouf"
cat > "${DEB_DIR}/usr/bin/ploufplouf" << 'WRAPPER'
#!/bin/sh
export GTK_USE_PORTAL=0
export GDK_DEBUG=no-portals
export XCURSOR_PATH="${XCURSOR_PATH:-/usr/share/icons:/usr/share/pixmaps}"
exec /opt/ploufplouf/tirage_equipes "$@"
WRAPPER
chmod 755 "${DEB_DIR}/usr/bin/ploufplouf"

echo "==> Fichier .desktop"
cat > "${DEB_DIR}/usr/share/applications/ploufplouf.desktop" << 'DESKTOP'
[Desktop Entry]
Name=PloufPlouf
Comment=Tirage d'équipes et tirage au sort pour la classe
Exec=/usr/bin/ploufplouf
Icon=ploufplouf
Terminal=false
Type=Application
Categories=Education;Utility;
DESKTOP

echo "==> DEBIAN/control"
cat > "${DEB_DIR}/DEBIAN/control" << CONTROL
Package: ploufplouf
Version: ${PKG_VER}
Section: education
Priority: optional
Architecture: amd64
Depends: libgtk-3-0, libgl1, libstdc++6, libicu70, libgcc-s1, libc6, libx11-6, libxcb1, libxkbcommon0
Maintainer: DesertYGL
Description: Tirage d'équipes et tirage au sort pour la classe (PloufPlouf)
 Logiciel libre pour former des équipes et tirer au sort parmi les élèves.
 Licence GPL-3.0.
CONTROL

echo "==> Construction du .deb"
dpkg-deb --root-owner-group --build "${DEB_DIR}" "${OUT_DIR}/ploufplouf_${PKG_VER}_amd64.deb"

echo "==> Terminé: ${OUT_DIR}/ploufplouf_${PKG_VER}_amd64.deb"
