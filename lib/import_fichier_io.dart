import 'dart:io';

Future<List<int>> lireFichier(String path) async {
  final f = File(path);
  return f.readAsBytes();
}
