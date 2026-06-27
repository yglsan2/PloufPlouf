/// Thème de noms d'équipes (10 noms pour 2 à 10 équipes).
class TeamNameTheme {
  const TeamNameTheme({
    required this.label,
    required this.emoji,
    required this.noms,
    this.description,
  });

  final String label;
  final String emoji;
  final List<String> noms;
  final String? description;
}

/// 16 thèmes complets — fun pour les élèves, variés pour les enseignants.
const List<TeamNameTheme> teamNameThemes = [
  TeamNameTheme(
    label: 'Numéros',
    emoji: '🔢',
    noms: [
      'Équipe 1', 'Équipe 2', 'Équipe 3', 'Équipe 4', 'Équipe 5',
      'Équipe 6', 'Équipe 7', 'Équipe 8', 'Équipe 9', 'Équipe 10',
    ],
    description: 'Classique et clair',
  ),
  TeamNameTheme(
    label: 'Animaux',
    emoji: '🦁',
    noms: [
      'Les Lions', 'Les Aigles', 'Les Dauphins', 'Les Loups', 'Les Ours',
      'Les Renards', 'Les Tigres', 'Les Éléphants', 'Les Pandas', 'Les Koalas',
    ],
  ),
  TeamNameTheme(
    label: 'Couleurs',
    emoji: '🎨',
    noms: [
      'Les Rouges', 'Les Bleus', 'Les Verts', 'Les Jaunes', 'Les Oranges',
      'Les Violets', 'Les Roses', 'Les Turquoise', 'Les Indigo', 'Les Corail',
    ],
  ),
  TeamNameTheme(
    label: 'Fruits',
    emoji: '🍎',
    noms: [
      'Les Pommes', 'Les Bananes', 'Les Fraises', 'Les Oranges', 'Les Pastèques',
      'Les Kiwis', 'Les Cerises', 'Les Pêches', 'Les Ananas', 'Les Mangues',
    ],
  ),
  TeamNameTheme(
    label: 'Dinosaures',
    emoji: '🦕',
    noms: [
      'Les T-Rex', 'Les Ptérodactyles', 'Les Tricératops', 'Les Diplodocus', 'Les Raptors',
      'Les Brontosaures', 'Les Stégosaures', 'Les Vélociraptors', 'Les Ankylosaures', 'Les Ptéranodons',
    ],
  ),
  TeamNameTheme(
    label: 'Pirates',
    emoji: '🏴‍☠️',
    noms: [
      'Les Perroquets', 'Les Canonniers', 'Les Moussaillons', 'Les Capitaines', 'Les Trésors',
      'Les Épées', 'Les Ancres', 'Les Compas', 'Les Sabres', 'Les Corsaires',
    ],
  ),
  TeamNameTheme(
    label: 'Espace',
    emoji: '🚀',
    noms: [
      'Les Fusées', 'Les Étoiles', 'Les Lunes', 'Les Mars', 'Les Satellites',
      'Les Astronautes', 'Les Comètes', 'Les Galaxies', 'Les OVNIs', 'Les Supernovas',
    ],
  ),
  TeamNameTheme(
    label: 'Magie',
    emoji: '✨',
    noms: [
      'Les Magiciens', 'Les Sorciers', 'Les Dragons', 'Les Licornes', 'Les Phénix',
      'Les Lutins', 'Les Fées', 'Les Trolls', 'Les Griffons', 'Les Sirènes',
    ],
  ),
  TeamNameTheme(
    label: 'Héros',
    emoji: '🦸',
    noms: [
      'Les Invincibles', 'Les Protecteurs', 'Les Voltigeurs', 'Les Gardiens', 'Les Courageux',
      'Les Éclairs', 'Les Titans', 'Les Aventuriers', 'Les Superstars', 'Les Champions',
    ],
    description: 'Noms originaux, sans marques déposées',
  ),
  TeamNameTheme(
    label: 'Sport',
    emoji: '⚽',
    noms: [
      'Les Sprinters', 'Les Rapides', 'Les Vainqueurs', 'Les Étoiles', 'Les Aigles',
      'Les Foudre', 'Les Titans', 'Les Dynamo', 'Les Phoenix', 'Les Warriors',
    ],
  ),
  TeamNameTheme(
    label: 'PloufPlouf',
    emoji: '🐄',
    noms: [
      'PloufPlouf 1', 'PloufPlouf 2', 'PloufPlouf 3', 'La Vache', 'Le Tonneau',
      'Les Bulles', 'Les Splash', 'Plouf Star', 'Plouf King', 'Plouf Queen',
    ],
    description: 'Thème officiel de l\'app',
  ),
  TeamNameTheme(
    label: 'Océan',
    emoji: '🌊',
    noms: [
      'Les Requins', 'Les Baleines', 'Les Pieuvres', 'Les Crabes', 'Les Hippocampes',
      'Les Méduses', 'Les Coraux', 'Les Voiliers', 'Les Plongeurs', 'Les Vagues',
    ],
  ),
  TeamNameTheme(
    label: 'Forêt',
    emoji: '🌲',
    noms: [
      'Les Chênes', 'Les Sapins', 'Les Écureuils', 'Les Hiboux', 'Les Cerfs',
      'Les Champignons', 'Les Ruisseaux', 'Les Feuilles', 'Les Castors', 'Les Renardeaux',
    ],
  ),
  TeamNameTheme(
    label: 'Musique',
    emoji: '🎵',
    noms: [
      'Les Solistes', 'Les Rythmiques', 'Les Mélodies', 'Les Harmonies', 'Les Notes',
      'Les Tambours', 'Les Violons', 'Les Jazz', 'Les Rockers', 'Les Choristes',
    ],
  ),
  TeamNameTheme(
    label: 'Monde',
    emoji: '🌍',
    noms: [
      'Les Parisiens', 'Les Tokyoïtes', 'Les Brésiliens', 'Les Égyptiens', 'Les Vikings',
      'Les Samouraïs', 'Les Incas', 'Les Kangourous', 'Les Alpins', 'Les Explorateurs',
    ],
  ),
  TeamNameTheme(
    label: 'Science',
    emoji: '🔬',
    noms: [
      'Les Atomiques', 'Les Voltaïques', 'Les Galilées', 'Les Newtons', 'Les Curie',
      'Les Labos', 'Les Inventeurs', 'Les Robots', 'Les Satellites', 'Les Génies',
    ],
  ),
  TeamNameTheme(
    label: 'Gourmand',
    emoji: '🍕',
    noms: [
      'Les Croissants', 'Les Crêpes', 'Les Gaufres', 'Les Bonbons', 'Les Chocolats',
      'Les Glaces', 'Les Gâteaux', 'Les Popcorn', 'Les Muffins', 'Les Donuts',
    ],
  ),
];

/// Pool aléatoire (tous les thèmes sauf Numéros).
List<String> buildRandomTeamNamePool() {
  final noms = <String>{};
  for (var i = 1; i < teamNameThemes.length; i++) {
    noms.addAll(teamNameThemes[i].noms);
  }
  return noms.toList();
}
