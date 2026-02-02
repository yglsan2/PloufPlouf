#!/bin/sh
# Script d'installation Arch Linux pour PloufPlouf.
# À exécuter depuis la racine du projet (tirage_equipes).
# Prérequis : Flutter installé, flutter build linux --release fonctionnel.

set -e
cd "$(dirname "$0")/../.."
PROJECT_ROOT="$(pwd)"

echo "Construction de l'application (release)..."
flutter build linux --release

BUNDLE="${PROJECT_ROOT}/build/linux/x64/release/bundle"
if [ ! -f "${BUNDLE}/tirage_equipes" ]; then
  echo "Erreur: bundle non trouvé. Exécutez ce script depuis la racine du projet."
  exit 1
fi

echo "Installation dans /opt/ploufplouf (nécessite sudo)..."
sudo mkdir -p /opt/ploufplouf
sudo cp -a "${BUNDLE}"/* /opt/ploufplouf/

echo "Installation du lanceur /usr/bin/ploufplouf..."
sudo tee /usr/bin/ploufplouf > /dev/null << 'WRAPPER'
#!/bin/sh
export GTK_USE_PORTAL=0
export GDK_DEBUG=no-portals
export XCURSOR_PATH="${XCURSOR_PATH:-/usr/share/icons:/usr/share/pixmaps}"
exec /opt/ploufplouf/tirage_equipes "$@"
WRAPPER
sudo chmod 755 /usr/bin/ploufplouf

echo "Installation du fichier .desktop..."
sudo mkdir -p /usr/share/applications
sudo tee /usr/share/applications/ploufplouf.desktop > /dev/null << 'DESKTOP'
[Desktop Entry]
Name=PloufPlouf
Comment=Tirage d'équipes et tirage au sort pour la classe
Exec=/usr/bin/ploufplouf
Icon=ploufplouf
Terminal=false
Type=Application
Categories=Education;Utility;
DESKTOP

echo "PloufPlouf est installé. Lancez avec: ploufplouf"
echo "Ou via le menu applications (Education / Utilitaires)."
