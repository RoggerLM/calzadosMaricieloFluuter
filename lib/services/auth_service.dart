import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Stream para escuchar cambios de autenticación
  Stream<firebase_auth.User?> get userStream => _auth.authStateChanges();

  // Login con email y contraseña
  Future<firebase_auth.User?> signInWithEmail(String email, String password) async {
    try {
      firebase_auth.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
      );
      return result.user;
    } catch (e) {
      print('Error en login: $e');
      return null;
    }
  }


  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Obtener usuario actual
  firebase_auth.User? get currentUser => _auth.currentUser;
}