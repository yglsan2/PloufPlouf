import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Génère le contenu texte des équipes (un nom par ligne, équipes séparées par des lignes vides).
String buildTxtEquipes(
  List<List<String>> equipes,
  List<String> nomsEquipes,
) {
  final buffer = StringBuffer();
  buffer.writeln('Équipes constituées');
  buffer.writeln('==================');
  buffer.writeln();
  for (var i = 0; i < equipes.length; i++) {
    final nom = i < nomsEquipes.length ? nomsEquipes[i] : 'Équipe ${i + 1}';
    buffer.writeln('$nom (${equipes[i].length})');
    for (final membre in equipes[i]) {
      buffer.writeln('  - $membre');
    }
    buffer.writeln();
  }
  return buffer.toString();
}

/// Génère les octets d'un fichier TXT.
List<int> buildTxtBytes(
  List<List<String>> equipes,
  List<String> nomsEquipes,
) {
  return utf8.encode(buildTxtEquipes(equipes, nomsEquipes));
}

/// Génère les octets d'un fichier ODT (LibreOffice) avec le contenu des équipes.
List<int> buildOdtBytes(
  List<List<String>> equipes,
  List<String> nomsEquipes,
) {
  final buffer = StringBuffer();
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.write(
    '<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" '
    'xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0">',
  );
  buffer.write('<office:body><office:text>');
  buffer.write('<text:p text:style-name="Title">Équipes constituées</text:p>');
  buffer.write('<text:p/>');
  for (var i = 0; i < equipes.length; i++) {
    final nom = i < nomsEquipes.length ? nomsEquipes[i] : 'Équipe ${i + 1}';
    buffer.write('<text:p text:style-name="Heading_1">$nom (${equipes[i].length})</text:p>');
    for (final membre in equipes[i]) {
      buffer.write('<text:p text:style-name="List">• $membre</text:p>');
    }
    buffer.write('<text:p/>');
  }
  buffer.write('</office:text></office:body></office:document-content>');
  final contentXml = utf8.encode(buffer.toString());
  final mimetype = utf8.encode('application/vnd.oasis.opendocument.text');
  final archive = Archive();
  archive.addFile(ArchiveFile('mimetype', mimetype.length, mimetype));
  archive.addFile(ArchiveFile('content.xml', contentXml.length, contentXml));
  return ZipEncoder().encode(archive) ?? [];
}

/// Génère les octets d'un fichier DOCX (Word) avec le contenu des équipes.
String _escapeXml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

List<int> buildDocxBytes(
  List<List<String>> equipes,
  List<String> nomsEquipes,
) {
  final buffer = StringBuffer();
  buffer.write(
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
    '<w:body>',
  );
  buffer.write('<w:p><w:r><w:t>Équipes constituées</w:t></w:r></w:p>');
  buffer.write('<w:p/>');
  for (var i = 0; i < equipes.length; i++) {
    final nom = i < nomsEquipes.length ? nomsEquipes[i] : 'Équipe ${i + 1}';
    buffer.write(
      '<w:p><w:r><w:t>${_escapeXml(nom)} (${equipes[i].length})</w:t></w:r></w:p>',
    );
    for (final membre in equipes[i]) {
      buffer.write('<w:p><w:r><w:t>• ${_escapeXml(membre)}</w:t></w:r></w:p>');
    }
    buffer.write('<w:p/>');
  }
  buffer.write('<w:p/><w:sectPr/></w:body></w:document>');
  final documentXml = utf8.encode(buffer.toString());
  final contentTypes = utf8.encode(
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="xml" ContentType="application/xml"/>'
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
    '</Types>',
  );
  final rels = utf8.encode(
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
    '</Relationships>',
  );
  final wordRels = utf8.encode(
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '</Relationships>',
  );
  final archive = Archive();
  archive.addFile(ArchiveFile('[Content_Types].xml', contentTypes.length, contentTypes));
  archive.addFile(ArchiveFile('_rels/.rels', rels.length, rels));
  archive.addFile(ArchiveFile('word/_rels/document.xml.rels', wordRels.length, wordRels));
  archive.addFile(ArchiveFile('word/document.xml', documentXml.length, documentXml));
  return ZipEncoder().encode(archive) ?? [];
}

/// Génère les octets d'un fichier PDF avec le contenu des équipes.
Future<List<int>> buildPdfBytes(
  List<List<String>> equipes,
  List<String> nomsEquipes,
) async {
  final pdf = pw.Document();
  final children = <pw.Widget>[
    pw.Header(level: 0, text: 'Équipes constituées'),
    pw.SizedBox(height: 20),
  ];
  for (var i = 0; i < equipes.length; i++) {
    final nom = i < nomsEquipes.length ? nomsEquipes[i] : 'Équipe ${i + 1}';
    children.add(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$nom (${equipes[i].length})',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          ...equipes[i].map(
            (m) => pw.Padding(
              padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
              child: pw.Text('• $m', style: const pw.TextStyle(fontSize: 12)),
            ),
          ),
          pw.SizedBox(height: 12),
        ],
      ),
    );
  }
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => children,
    ),
  );
  return (await pdf.save()).toList();
}

/// Format CSV Pronote / Ecole Directe : point-virgule (;), UTF-8 avec BOM.
/// En-tête "Prénom;Nom" pour réimport dans Pronote ou Ecole Directe.
typedef EleveExport = ({String prenom, String nom});

/// Génère les octets d'un CSV liste d'élèves (Prénom;Nom) pour Pronote / Ecole Directe.
/// UTF-8 avec BOM pour Excel français.
List<int> buildCsvPronoteListeBytes(List<EleveExport> eleves) {
  const bom = [0xEF, 0xBB, 0xBF];
  String escapeCsv(String s) {
    if (s.contains(';') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
  final lines = <String>['Prénom;Nom'];
  for (final e in eleves) {
    lines.add('${escapeCsv(e.prenom)};${escapeCsv(e.nom)}');
  }
  return [...bom, ...utf8.encode(lines.join('\r\n'))];
}

/// Enregistre la liste d'élèves au format CSV Pronote / Ecole Directe.
/// Retourne le chemin du fichier si enregistré (ou '' si boîte dialogue utilisée), null si échec/annulation.
/// Sur Linux, si la boîte (zenity) échoue (ex. "zenithy" introuvable), enregistre dans le dossier Documents.
Future<String?> enregistrerListeElevesPronote(List<EleveExport> eleves) async {
  if (eleves.isEmpty) return null;
  final bytes = buildCsvPronoteListeBytes(eleves);
  final defaultName = 'liste_eleves_${DateTime.now().millisecondsSinceEpoch}.csv';
  try {
    await FilePicker.platform.saveFile(
      fileName: defaultName,
      bytes: Uint8List.fromList(bytes),
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    return '';
  } catch (e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('zenithy') || msg.contains('zenity') || msg.contains('path') || msg.contains('not find')) {
      try {
        final dir = Platform.isLinux
            ? await getApplicationDocumentsDirectory()
            : await getApplicationSupportDirectory();
        final path = '${dir.path}/$defaultName';
        await File(path).writeAsBytes(bytes);
        return path;
      } catch (_) {
        rethrow;
      }
    }
    rethrow;
  }
}

/// Ouvre la boîte d'enregistrement et enregistre les équipes au format choisi.
/// Retourne true si l'enregistrement a réussi ou si l'utilisateur a annulé sans erreur, false en cas d'erreur.
Future<bool> enregistrerEquipes(
  List<List<String>> equipes,
  List<String> nomsEquipes,
  String format,
) async {
  if (equipes.isEmpty) return false;
  final ext = format.toLowerCase();
  final defaultName = 'equipes_${DateTime.now().millisecondsSinceEpoch}.$ext';
  List<int> bytes;
  try {
    if (ext == 'txt') {
      bytes = buildTxtBytes(equipes, nomsEquipes);
    } else if (ext == 'odt') {
      bytes = buildOdtBytes(equipes, nomsEquipes);
    } else if (ext == 'docx') {
      bytes = buildDocxBytes(equipes, nomsEquipes);
    } else if (ext == 'pdf') {
      bytes = await buildPdfBytes(equipes, nomsEquipes);
    } else {
      return false;
    }
  } catch (e) {
    rethrow;
  }
  await FilePicker.platform.saveFile(
    fileName: defaultName,
    bytes: Uint8List.fromList(bytes),
    type: FileType.custom,
    allowedExtensions: [ext],
  );
  return true;
}
