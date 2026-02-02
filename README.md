# PloufPlouf

**Tirage d’équipes et tirage au sort pour la classe.**  
Application Flutter pour former des équipes (2 à 10) parmi une liste d’élèves (jusqu’à 50), et pour tirer au sort des gagnants parmi les volontaires.

---

## Créateur

**DesertYGL**

---

## Mode d’emploi

### Onglet « Équipes »

1. **Liste des élèves**  
   La grille affiche jusqu’à 50 élèves (par défaut « Élève 1 », « Élève 2 », etc.).  
   - Cliquez sur une cellule pour **modifier** le prénom et le nom.  
   - Utilisez **Tout cocher** / **Tout décocher** pour cocher ou décocher tous les élèves comme participants.  
   - **Ajouter un élève** : ajoute une ligne (dans la limite de 50).  
   - **Valider les noms entrés** : enlève les lignes vides ou par défaut et garde les noms saisis.

2. **Participants**  
   Cochez les élèves qui **participent** au tirage d’équipes. Le nombre de participants s’affiche.  
   Option **« Cocher les identités automatiquement »** : les lignes avec un prénom ou un nom saisi sont cochées comme participantes.

3. **Noms des équipes**  
   Choisissez un thème (Animaux, Couleurs, etc.) ou **« Choix tout aléatoire »** pour des noms aléatoires.

4. **Lancer le tirage**  
   Cliquez sur **« 2 équipes »**, **« 3 équipes »**, … **« 10 équipes »**.  
   Les équipes sont affichées avec une répartition aléatoire et équilibrée. Vous pouvez modifier les noms d’équipes et exporter le résultat.

### Onglet « Tirage au sort »

1. **Volontaires**  
   Cochez les élèves qui sont **volontaires** pour le tirage au sort.

2. **Nombre de gagnants**  
   Indiquez combien de gagnants vous voulez tirer.

3. **Tirer au sort**  
   Cliquez sur **« Tirer au sort »**. Les gagnants s’affichent ; vous pouvez les modifier si besoin.

### Import et export

- **Importer** (icône dossier avec flèche) : importer une liste d’élèves depuis un fichier (TXT, CSV, PDF, ODT, DOCX, XLSX). Détection des colonnes Prénom / Nom (compatible Pronote, École Directe).  
- **Exporter la liste d’élèves** (icône téléchargement) : enregistrer la liste actuelle en CSV (Prénom;Nom).  
- **Exporter / Enregistrer les équipes** : proposé après un tirage d’équipes (CSV ou PDF).

### À propos et licence

- **À propos** (icône ℹ️ dans la barre) : affiche le créateur (DesertYGL) et la licence GPL-3.0.

---

## Lancer l’application (développement)

```bash
git clone https://github.com/yglsan2/PloufPlouf.git
cd PloufPlouf
flutter pub get
flutter run
```

Compatible Android, iOS, Web, Linux, macOS, Windows.

### Linux

- **Erreurs XDG / GDBus au démarrage** : lancez avec le script qui désactive le portail :
  ```bash
  ./linux/run_sans_portal.sh
  ```
  Ou à la main : `GTK_USE_PORTAL=0 GDK_DEBUG=no-portals flutter run -d linux`
- **Import / export de fichiers** : si la boîte de dialogue échoue, installez zenity (`sudo apt install zenity`) ou utilisez le champ « Chemin du fichier » dans la fenêtre d’import.
- **Curseur** (« Unable to load from the cursor theme ») : le script et le binaire définissent déjà `XCURSOR_PATH` ; le message peut rester affiché mais est inoffensif.

---

## Installation (paquets)

- **Arch Linux** : voir [packaging/arch/README.md](packaging/arch/README.md) (script `install.sh` ou PKGBUILD).  
- **Ubuntu** : paquet .deb construit via Docker, voir [packaging/ubuntu/README.md](packaging/ubuntu/README.md) et `./packaging/ubuntu/build-deb.sh`.  
  Installation du .deb : `sudo dpkg -i ploufplouf_1.0.0_amd64.deb` puis `sudo apt-get install -f` si des dépendances manquent.

---

## Licence

**GPL-3.0 (GNU General Public License v3.0)**

PloufPlouf — Copyleft (C) DesertYGL.

Ce programme est un logiciel libre : vous pouvez le redistribuer et le modifier selon les termes de la licence GNU GPL v3. Il est fourni « tel quel », sans garantie. Vous devez avoir reçu une copie de la licence avec le programme ; sinon, voir <https://www.gnu.org/licenses/gpl-3.0.html>.

- Texte complet de la licence : [LICENSE](LICENSE) (en-tête et renvoi au texte officiel).  
- Texte intégral GPL-3.0 : <https://www.gnu.org/licenses/gpl-3.0.html>.
