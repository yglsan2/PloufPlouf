# Paquet .deb pour Ubuntu

Construction du `.deb` dans un conteneur Docker (Ubuntu 22.04) pour éviter les problèmes de dépendances obsolètes ou d’environnement.

## Prérequis

- Docker installé sur la machine hôte (Arch, Ubuntu, etc.).
- Votre utilisateur doit pouvoir lancer Docker : si vous avez « permission denied » sur `docker.sock`, ajoutez-vous au groupe `docker` puis reconnectez-vous :
  ```bash
  sudo usermod -aG docker $USER
  newgrp docker   # ou déconnexion/reconnexion
  ```

## Génération du .deb

Depuis la **racine du projet** (répertoire `tirage_equipes`) :

```bash
chmod +x packaging/ubuntu/build-deb.sh
./packaging/ubuntu/build-deb.sh
```

La première exécution peut être longue (téléchargement de l’image Ubuntu + Flutter).  
Le paquet est produit dans : `packaging/ubuntu/out/ploufplouf_1.0.1_amd64.deb`.

## Installation sur Ubuntu

```bash
sudo dpkg -i ploufplouf_1.0.1_amd64.deb
# Si des dépendances manquent :
sudo apt-get install -f
```

Lancement : `ploufplouf` ou via le menu (Education / Utilitaires).

## Désinstallation

```bash
sudo apt remove ploufplouf
```
