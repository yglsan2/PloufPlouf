#!/bin/bash
# Corrige les permissions après un build/run en root.
# À lancer une seule fois : ./fix-permissions.sh
# (ou : sudo chown -R "$USER:$USER" .)

set -e
cd "$(dirname "$0")"
echo "Réattribution de $(pwd) à l'utilisateur $USER..."
sudo chown -R "$USER:$USER" .
echo "Permissions corrigées. Vous pouvez lancer : flutter run -d linux"
flutter clean
