# APK Android (PloufPlouf)

Construction de l’APK release pour smartphones et tablettes Android.

## Prérequis

- Flutter SDK installé
- Android SDK (configuré via `flutter doctor`)

Vérifier :

```bash
flutter doctor
```

## Génération de l’APK

Depuis la **racine du projet** (répertoire `tirage_equipes`) :

```bash
chmod +x packaging/android/build-apk.sh
./packaging/android/build-apk.sh
```

L’APK est produit dans : `packaging/android/out/ploufplouf_1.0.0.apk` (version selon `pubspec.yaml`).

## Installation sur Android

1. Transférer le fichier `.apk` sur le téléphone (USB, cloud, etc.).
2. Ouvrir le fichier et accepter l’installation (activer « Sources inconnues » si demandé).
3. L’app apparaît dans le tiroir d’applications sous le nom **PloufPlouf**.

## Variantes (optionnel)

- **APK par ABI** (taille réduite par appareil) :  
  `flutter build apk --release --split-per-abi`  
  → génère `app-armeabi-v7a-release.apk`, `app-arm64-v8a-release.apk`, etc.

- **App Bundle** (pour publication sur le Play Store) :  
  `flutter build appbundle --release`  
  → génère `build/app/outputs/bundle/release/app-release.aab`
