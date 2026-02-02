import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:xml/xml.dart';

import 'import_fichier_stub.dart' if (dart.library.io) 'import_fichier_io.dart' as lire_fichier;

/// Un élève importé avec prénom, nom et optionnellement genre (Pronote / Ecole Directe).
typedef EleveImport = ({String prenom, String nom, String? genre});

/// Résultat d'une tentative d'import : texte brut et/ou liste structurée (prénom, nom), ou erreur.
class ResultatImportFichier {
  ResultatImportFichier({this.texte, this.eleves, this.erreur});

  /// Texte brut (une ligne ou un nom par ligne) pour import manuel.
  final String? texte;
  /// Liste (prénom, nom) détectée depuis CSV/Excel (Pronote, Ecole Directe, etc.).
  final List<EleveImport>? eleves;
  final String? erreur;

  bool get ok => (texte != null || (eleves != null && eleves!.isNotEmpty)) && erreur == null;
}

/// Ouvre le sélecteur de fichier et extrait le texte ou la liste d'élèves (prénom, nom).
/// Formats : TXT, CSV, XLSX (Pronote, Ecole Directe, ENT…), PDF, ODT, DOCX.
Future<ResultatImportFichier> importerTexteDepuisFichier() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'csv', 'xlsx', 'pdf', 'odt', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return ResultatImportFichier(erreur: null);
    }
    final file = result.files.single;
    final path = file.path;
    final bytes = file.bytes;
    final name = file.name.toLowerCase();

    if (bytes == null && path == null) {
      return ResultatImportFichier(erreur: 'Fichier inaccessible.');
    }

    final data = bytes ?? await _lireFichier(path!);

    if (name.endsWith('.txt')) {
      return _extraireTxt(data, path);
    }
    if (name.endsWith('.csv')) {
      return _extraireCsv(data);
    }
    if (name.endsWith('.xlsx')) {
      return _extraireXlsx(data);
    }
    if (name.endsWith('.odt')) {
      return _extraireOdt(data);
    }
    if (name.endsWith('.docx')) {
      return _extraireDocx(data);
    }
    if (name.endsWith('.pdf')) {
      return await _extrairePdf(path, bytes);
    }

    return ResultatImportFichier(erreur: 'Format non supporté.');
  } catch (e) {
    return ResultatImportFichier(
      erreur: 'Erreur : $e',
    );
  }
}

/// Importe depuis un chemin de fichier (secours Linux quand le sélecteur zenity échoue).
Future<ResultatImportFichier> importerFichierDepuisChemin(String path) async {
  final p = path.trim();
  if (p.isEmpty) {
    return ResultatImportFichier(erreur: 'Chemin vide.');
  }
  try {
    final data = await _lireFichier(p);
    final name = p.split(RegExp(r'[/\\]')).last.toLowerCase();
    if (name.endsWith('.txt')) {
      return _extraireTxt(data, p);
    }
    if (name.endsWith('.csv')) {
      return _extraireCsv(data);
    }
    if (name.endsWith('.xlsx')) {
      return _extraireXlsx(data);
    }
    if (name.endsWith('.odt')) {
      return _extraireOdt(data);
    }
    if (name.endsWith('.docx')) {
      return _extraireDocx(data);
    }
    if (name.endsWith('.pdf')) {
      return await _extrairePdf(p, data);
    }
    return ResultatImportFichier(erreur: 'Format non supporté (txt, csv, xlsx, pdf, odt, docx).');
  } catch (e) {
    return ResultatImportFichier(
      erreur: 'Impossible de lire le fichier : $e',
    );
  }
}

Future<List<int>> _lireFichier(String path) async {
  return lire_fichier.lireFichier(path);
}

/// Détecte le délimiteur CSV (; prioritaire pour Pronote/Excel FR, puis , puis \t).
String _detecterDelimiteur(String firstLine) {
  if (firstLine.contains(';')) {
    return ';';
  }
  if (firstLine.contains('\t')) {
    return '\t';
  }
  return ',';
}

/// Normalise un en-tête pour la recherche (minuscules, sans BOM, sans espaces superflus).
String _normaliserEnTete(String s) {
  s = s.trim().toLowerCase();
  if (s.startsWith('\uFEFF')) {
    s = s.substring(1);
  }
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Variantes Pronote / Ecole Directe pour la colonne "Nom".
const _nomsColonnesNom = [
  'nom', 'nom de famille', 'nom de l\'élève', 'nom de l’élève', 'nom élève',
  'nom de l’eleve', 'nom de l\'eleve', 'last name', 'name',
];

/// Variantes Pronote / Ecole Directe pour la colonne "Prénom".
const _nomsColonnesPrenom = [
  'prénom', 'prenom', 'prénom de l\'élève', 'prénom de l’élève', 'prénom élève',
  'prénom de l’eleve', 'prénom de l\'eleve', 'prenom de l\'eleve', 'first name',
];

/// Colonnes "nom complet" (une seule colonne : on découpe en prénom + nom).
const _nomsColonnesEleve = [
  'élève', 'eleve', 'nom complet', 'nom et prénom', 'nom et prenom',
  'nom et prénom de l\'élève', 'nom de l\'élève', 'nom de l’élève',
];

/// Cherche les indices des colonnes nom, prénom et optionnellement "Élève" (nom complet).
void _trouverColonnesNomPrenom(
  List<String> headers,
  void Function(int? iNom, int? iPrenom, int? iEleve) onFound,
) {
  int? iNom;
  int? iPrenom;
  int? iEleve;
  for (var i = 0; i < headers.length; i++) {
    final h = _normaliserEnTete(headers[i]);
    if (_nomsColonnesNom.contains(h)) {
      iNom = i;
    } else if (_nomsColonnesPrenom.contains(h)) {
      iPrenom = i;
    } else if (_nomsColonnesEleve.contains(h)) {
      iEleve = i;
    }
  }
  onFound(iNom, iPrenom, iEleve);
}

/// Cherche l'indice de la colonne Sexe/Genre (Pronote : "Sexe", Ecole Directe : "Genre").
int? _trouverColonneSexe(List<String> headers) {
  for (var i = 0; i < headers.length; i++) {
    final h = _normaliserEnTete(headers[i]);
    if (h == 'sexe' || h == 'genre' || h == 'civilité' || h == 'civilite') {
      return i;
    }
  }
  return null;
}

/// Normalise une valeur Sexe/Genre vers "F" ou "M" (Pronote : F/M ou Fille/Garçon).
String? _normaliserGenre(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final v = value.trim().toLowerCase();
  if (v == 'f' || v == 'fille' || v == 'féminin' || v == 'feminin') return 'F';
  if (v == 'm' || v == 'garçon' || v == 'garcon' || v == 'g' || v == 'masculin') return 'M';
  return null;
}

/// Découpe "Prénom Nom" (dernier mot = nom, reste = prénom) — convention française.
(String prenom, String nom) _decouperNomComplet(String full) {
  final t = full.trim();
  if (t.isEmpty) return ('', '');
  final parts = t.split(RegExp(r'\s+'));
  if (parts.length == 1) return (parts[0], '');
  final nom = parts.last;
  final prenom = parts.sublist(0, parts.length - 1).join(' ');
  return (prenom, nom);
}

/// Décode les octets en texte (UTF-8 prioritaire, puis Windows-1252 / Latin1 pour Pronote/Excel FR).
String _decoderCsv(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } catch (_) {
    try {
      return latin1.decode(bytes);
    } catch (_) {
      // Windows-1252 (Excel français) : proche de Latin1 pour les caractères courants
      return latin1.decode(bytes);
    }
  }
}

/// Découpe une ligne CSV en respectant les guillemets (Pronote/Excel exportent parfois "Nom";"Prénom").
List<String> _splitCsvLine(String line, String delim) {
  final cells = <String>[];
  var i = 0;
  while (i < line.length) {
    if (line[i] == '"') {
      final end = line.indexOf('"', i + 1);
      if (end == -1) {
        cells.add(line.substring(i + 1).replaceAll('""', '"').trim());
        break;
      }
      cells.add(line.substring(i + 1, end).replaceAll('""', '"').trim());
      i = end + 1;
      if (i < line.length && line[i] == delim) i++;
      continue;
    }
    final nextDelim = line.indexOf(delim, i);
    if (nextDelim == -1) {
      cells.add(line.substring(i).trim());
      break;
    }
    cells.add(line.substring(i, nextDelim).trim());
    i = nextDelim + 1;
  }
  return cells;
}

ResultatImportFichier _extraireCsv(List<int> bytes) {
  try {
    final texte = _decoderCsv(bytes)
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final lines = texte.split('\n').where((s) => s.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      return ResultatImportFichier(texte: texte);
    }
    final delim = _detecterDelimiteur(lines[0]);
    final headers = _splitCsvLine(lines[0], delim);
    int? iNom;
    int? iPrenom;
    int? iEleve;
    _trouverColonnesNomPrenom(headers, (n, p, e) {
      iNom = n;
      iPrenom = p;
      iEleve = e;
    });
    final iSexe = _trouverColonneSexe(headers);

    final bool useStructured = (iNom != null || iPrenom != null) || (iEleve != null);
    if (useStructured) {
      final eleves = <EleveImport>[];
      for (var r = 1; r < lines.length; r++) {
        final cells = _splitCsvLine(lines[r], delim);
        String prenom = '';
        String nom = '';
        final ie = iEleve;
        if (ie != null && ie < cells.length && cells[ie].trim().isNotEmpty) {
          final full = cells[ie].trim();
          final split = _decouperNomComplet(full);
          prenom = split.$1;
          nom = split.$2;
        }
        final ip = iPrenom;
        if (ip != null && ip < cells.length) {
          prenom = cells[ip].trim();
        }
        final in_ = iNom;
        if (in_ != null && in_ < cells.length) {
          nom = cells[in_].trim();
        }
        if (prenom.isEmpty && nom.isEmpty) {
          continue;
        }
        String? genre;
        final isx = iSexe;
        if (isx != null && isx < cells.length && cells[isx].trim().isNotEmpty) {
          genre = _normaliserGenre(cells[isx]);
        }
        eleves.add((prenom: prenom, nom: nom, genre: genre));
      }
      if (eleves.isNotEmpty) {
        return ResultatImportFichier(eleves: eleves);
      }
    }
    return ResultatImportFichier(texte: texte);
  } catch (e) {
    return ResultatImportFichier(erreur: 'Impossible de lire le CSV : $e');
  }
}

String _cellAt(List<dynamic> row, int index) {
  if (index < 0 || index >= row.length) return '';
  return _cellToString(row[index]);
}

ResultatImportFichier _extraireXlsx(List<int> bytes) {
  try {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      return ResultatImportFichier(erreur: 'Fichier Excel vide.');
    }
    final sheet = excel.tables.values.first;
    if (sheet.rows.isEmpty) {
      return ResultatImportFichier(erreur: 'Feuille Excel vide.');
    }
    final headerRow = sheet.rows.first;
    final headers = headerRow.map((c) => _cellToString(c)).toList();
    int? iNom;
    int? iPrenom;
    int? iEleve;
    _trouverColonnesNomPrenom(headers, (n, p, e) {
      iNom = n;
      iPrenom = p;
      iEleve = e;
    });
    final iSexe = _trouverColonneSexe(headers);

    final bool useStructured = (iNom != null || iPrenom != null) || (iEleve != null);
    if (useStructured) {
      final eleves = <EleveImport>[];
      for (var r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        String prenom = '';
        String nom = '';
        final ie = iEleve;
        if (ie != null) {
          final full = _cellAt(row, ie).trim();
          if (full.isNotEmpty) {
            final split = _decouperNomComplet(full);
            prenom = split.$1;
            nom = split.$2;
          }
        }
        final ip = iPrenom;
        if (ip != null) {
          prenom = _cellAt(row, ip).trim();
        }
        final in_ = iNom;
        if (in_ != null) {
          nom = _cellAt(row, in_).trim();
        }
        if (prenom.isEmpty && nom.isEmpty) {
          continue;
        }
        String? genre;
        final isx = iSexe;
        if (isx != null) {
          final v = _cellAt(row, isx).trim();
          if (v.isNotEmpty) genre = _normaliserGenre(v);
        }
        eleves.add((prenom: prenom, nom: nom, genre: genre));
      }
      if (eleves.isNotEmpty) {
        return ResultatImportFichier(eleves: eleves);
      }
    }
    final buffer = StringBuffer();
    for (final row in sheet.rows) {
      buffer.writeln(row.map((c) => _cellToString(c)).join('\t'));
    }
    return ResultatImportFichier(texte: buffer.toString().trim());
  } catch (e) {
    return ResultatImportFichier(erreur: 'Impossible de lire le fichier Excel : $e');
  }
}

String _cellToString(dynamic cell) {
  if (cell == null) {
    return '';
  }
  final Data? data = cell is Data ? cell : null;
  final CellValue? v = data?.value;
  if (v == null) {
    return '';
  }
  return switch (v) {
    TextCellValue(:final value) => (value.text ?? '').trim(),
    IntCellValue(:final value) => value.toString(),
    DoubleCellValue(:final value) => value.toString(),
    BoolCellValue(:final value) => value.toString(),
    _ => v.toString().trim(),
  };
}

ResultatImportFichier _extraireTxt(List<int> bytes, [String? path]) {
  try {
    String texte;
    try {
      texte = utf8.decode(bytes);
    } catch (_) {
      texte = latin1.decode(bytes);
    }
    texte = texte.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    return ResultatImportFichier(texte: texte);
  } catch (e) {
    return ResultatImportFichier(erreur: 'Impossible de lire le fichier texte : $e');
  }
}

ResultatImportFichier _extraireOdt(List<int> bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    final content = archive.findFile('content.xml');
    if (content == null) {
      return ResultatImportFichier(erreur: 'Fichier ODT invalide (content.xml absent).');
    }
    final xml = XmlDocument.parse(utf8.decode(content.content as List<int>));
    final buffer = StringBuffer();
    for (final p in xml.findAllElements('text:p')) {
      final line = p.descendants
          .whereType<XmlText>()
          .map((t) => t.value.trim())
          .where((s) => s.isNotEmpty)
          .join(' ')
          .trim();
      if (line.isNotEmpty) buffer.writeln(line);
    }
    final texte = buffer.toString().trim();
    return ResultatImportFichier(texte: texte.isEmpty ? null : texte);
  } catch (e) {
    return ResultatImportFichier(erreur: 'Impossible de lire le fichier ODT : $e');
  }
}

ResultatImportFichier _extraireDocx(List<int> bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    final content = archive.findFile('word/document.xml');
    if (content == null) {
      return ResultatImportFichier(erreur: 'Fichier Word invalide (document.xml absent).');
    }
    final xml = XmlDocument.parse(utf8.decode(content.content as List<int>));
    final buffer = StringBuffer();
    for (final p in xml.findAllElements('w:p')) {
      for (final el in p.findAllElements('w:t')) {
        buffer.write(el.innerText);
      }
      buffer.writeln();
    }
    final texte = buffer.toString().replaceAll(RegExp(r'\n{2,}'), '\n').trim();
    return ResultatImportFichier(texte: texte.isEmpty ? null : texte);
  } catch (e) {
    return ResultatImportFichier(erreur: 'Impossible de lire le fichier Word : $e');
  }
}

Future<ResultatImportFichier> _extrairePdf(String? path, List<int>? bytes) async {
  try {
    if (path != null && path.isNotEmpty) {
      final doc = await PDFDoc.fromPath(path);
      final text = await doc.text;
      return ResultatImportFichier(texte: text.trim());
    }
    return ResultatImportFichier(
      erreur: 'Sur cette plateforme, choisissez un fichier PDF depuis l’appareil (le PDF doit être accessible par chemin).',
    );
  } catch (e) {
    return ResultatImportFichier(erreur: 'Impossible de lire le PDF : $e');
  }
}
