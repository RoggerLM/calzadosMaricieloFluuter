import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> obtenerUrlImagen(String imagenId) async {
    try {
      final ref = _storage.ref().child(imagenId);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error obteniendo URL: $e");
      return null;
    }
  }
}
