#!/bin/sh
# Lance l'app Linux sans utiliser le portail XDG (évite les erreurs
# "Failed to read XDG desktop portal settings" et "GDBus.Error: AccessDenied").
# XCURSOR_PATH évite "Unable to load from the cursor theme".
export GTK_USE_PORTAL=0
export GDK_DEBUG=no-portals
export XCURSOR_PATH="${XCURSOR_PATH:-/usr/share/icons:/usr/share/pixmaps:$HOME/.icons}"
cd "$(dirname "$0")/.." && exec flutter run -d linux "$@"
