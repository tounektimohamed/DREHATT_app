import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../components/alert.dart';

class AuthService {
  // Instance de GoogleSignIn avec les scopes nécessaires
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      // tu peux ajouter d'autres scopes si nécessaire
    ],
  );

  /// Connexion avec Google
  Future<UserCredential> signInWithGoogle(BuildContext context) async {
    // Déconnexion préalable pour éviter les anciennes sessions
    await _googleSignIn.signOut();

    // Lancement du processus de connexion Google
    final GoogleSignInAccount? gUser = await _googleSignIn.signIn();

    // Si l’utilisateur annule la connexion
    if (gUser == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Connexion annulée par l’utilisateur',
      );
    }

    // Récupérer les informations d’authentification Google
    final GoogleSignInAuthentication gAuth = await gUser.authentication;

    // Créer les credentials Firebase à partir du token Google
    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    UserCredential? userCredential;

    try {
      // Affichage d’un loader pendant la connexion
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color.fromRGBO(7, 82, 96, 1),
            ),
          );
        },
      );

      // Connexion Firebase
      userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Fermeture du loader après connexion
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      // En cas d’erreur, fermer le loader
      Navigator.of(context).pop();

      // Afficher une alerte personnalisée
      showDialog(
        context: context,
        builder: (context) {
          return Alert_Dialog(
            isError: true,
            alertTitle: 'Erreur',
            errorMessage: e.message ?? 'Une erreur inconnue est survenue',
            buttonText: 'Fermer',
          );
        },
      );
    }

    return userCredential!;
  }

  /// Déconnexion Google + Firebase
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
  }

  /// Vérifie si un utilisateur est déjà connecté
  User? get currentUser => FirebaseAuth.instance.currentUser;
}
