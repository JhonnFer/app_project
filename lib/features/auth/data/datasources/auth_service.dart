// lib/features/auth/data/datasources/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AuthRemoteDataSource {
  Future<UserCredential> signIn(String email, String password);
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  });
  Future<void> signOut();
  Future<void> resetPassword(String email);
  User? getCurrentUser();
  Stream<User?> authStateChanges();
  Future<Map<String, dynamic>?> getUserData(String uid);
  Future<Map<String, dynamic>> getUserServices(String uid);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  @override
  User? getCurrentUser() => _auth.currentUser;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await credential.user?.updateDisplayName(name);

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email.trim(),
        'name': name,
        'role': role,
        'phone': phone,
        'rating': role == 'technician' ? 0.0 : null,
        'serviceCount': role == 'technician' ? 0 : null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> getUserServices(String uid) async {
    try {
      // Obtener servicios del usuario (para clientes: servicios solicitados)
      final servicesSnapshot = await _firestore
          .collection('services')
          .where('clientId', isEqualTo: uid)
          .get();

      // Contar por estado
      int inProgress = 0;
      int completed = 0;

      for (var doc in servicesSnapshot.docs) {
        final status = doc.data()['status'] as String?;
        if (status == 'in_progress') {
          inProgress++;
        } else if (status == 'completed') {
          completed++;
        }
      }

      // Obtener servicios recientes
      final recentServices = await _firestore
          .collection('services')
          .where('clientId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(2)
          .get();

      return {
        'inProgress': inProgress,
        'completed': completed,
        'recentServices': recentServices.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? 'Sin título',
            'technician': data['technicianName'] ?? 'Sin asignar',
            'status': data['status'] ?? 'pending',
            'rating': data['rating'] ?? 0.0,
          };
        }).toList(),
      };
    } catch (e) {
      return {
        'inProgress': 0,
        'completed': 0,
        'recentServices': [],
      };
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'operation-not-allowed':
        return 'Operación no permitida.';
      case 'invalid-credential':
        return 'Las credenciales son inválidas o han expirado.';
      default:
        return 'Error de autenticación: ${e.message ?? 'Error desconocido'}';
    }
  }
}
