# Installation sur Arch Linux

## Option 1 : Script d’installation rapide

Depuis la racine du projet (là où se trouve `pubspec.yaml`) :

```bash
chmod +x packaging/arch/install.sh
./packaging/arch/install.sh
```

Prérequis : Flutter installé (`pacman -S flutter` ou AUR `flutter-bin`).

## Option 2 : Paquet avec makepkg

1. Créez une archive du projet (sans `build/`) :
   ```bash
   cd ..
   tar --exclude=tirage_equipes/build -czvf ploufplouf-1.0.0.tar.gz tirage_equipes/
   mv ploufplouf-1.0.0.tar.gz tirage_equipes/packaging/arch/
   ```

2. Dans `packaging/arch/PKGBUILD`, adaptez `source` pour pointer vers cette archive et `sha256sums`.

3. Depuis `packaging/arch/` :
   ```bash
   makepkg -si
   ```
   (Flutter doit être dans le PATH au moment du build.)

## Désinstallation (script)

```bash
sudo rm -rf /opt/ploufplouf
sudo rm -f /usr/bin/ploufplouf
sudo rm -f /usr/share/applications/ploufplouf.desktop
```
