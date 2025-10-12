import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../components/alert.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb 
        ? '562475984196-4rmbp26md9fq33pffjbpcmurlompl0mb.apps.googleusercontent.com' // Pour le web seulement
        : null, // Pour mobile, pas besoin de clientId
  );

  Future<UserCredential> signInWithGoogle(BuildContext context) async {
    try {
      // Afficher l'indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color.fromRGBO(7, 82, 96, 1),
          ),
        ),
      );

      // Déconnexion préalable et démarrage du processus
      await _googleSignIn.signOut();
      
      // Attendre un peu après la déconnexion
      await Future.delayed(const Duration(milliseconds: 500));
      
      GoogleSignInAccount? gUser;
      
      // Essayer plusieurs approches pour le web
      if (kIsWeb) {
        try {
          // Essayer d'abord signInSilently
          gUser = await _googleSignIn.signInSilently();
          if (gUser == null) {
            // Si signInSilently retourne null, essayer signIn
            gUser = await _googleSignIn.signIn();
          }
        } catch (e) {
          // En cas d'erreur avec signInSilently, essayer directement signIn
          gUser = await _googleSignIn.signIn();
        }
      } else {
        // Pour mobile, on utilise directement signIn
        gUser = await _googleSignIn.signIn();
      }
      
      if (gUser == null) {
        throw Exception("Connexion annulée par l'utilisateur");
      }

      // Obtenir les informations d'authentification
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // Vérifier que nous avons les tokens nécessaires
      if (gAuth.idToken == null && gAuth.accessToken == null) {
        throw Exception("Tokens d'authentification manquants");
      }

      // Créer les credentials Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      // Connexion avec Firebase
      final userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Fermer l'indicateur de chargement
      if (Navigator.canPop(context)) Navigator.of(context).pop();

      return userCredential;
    } catch (e) {
      // Fermer l'indicateur de chargement en cas d'erreur
      if (Navigator.canPop(context)) Navigator.of(context).pop();

      // Gestion des erreurs spécifiques
      String errorMessage = "Erreur de connexion";
      
      if (e is FirebaseAuthException) {
        errorMessage = _mapFirebaseError(e.code);
      } else if (e.toString().contains("popup_closed") || 
                 e.toString().contains("popup_closed_by_user") ||
                 e.toString().contains("Connexion annulée")) {
        errorMessage = "La connexion a été annulée";
      } else if (e.toString().contains("access_denied")) {
        errorMessage = "Connexion refusée par l'utilisateur";
      } else if (e.toString().contains("unknown_reason") ||
                 e.toString().contains("IdentityCredentialError")) {
        errorMessage = "Erreur technique avec Google Sign-In. Veuillez réessayer.";
      } else if (e.toString().contains("Tokens d'authentification manquants")) {
        errorMessage = "Problème d'authentification avec Google";
      }

      // Afficher l'alerte seulement si ce n'est pas une simple annulation
      if (!errorMessage.contains("annulée")) {
        showDialog(
          context: context,
          builder: (context) => Alert_Dialog(
            isError: true,
            alertTitle: 'Erreur',
            errorMessage: errorMessage,
            buttonText: 'OK',
          ),
        );
      }

      rethrow;
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec cet email';
      case 'invalid-credential':
        return 'Identifiants invalides';
      case 'operation-not-allowed':
        return 'Connexion Google non autorisée';
      case 'user-disabled':
        return 'Compte désactivé';
      case 'user-not-found':
        return 'Compte introuvable';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-verification-code':
        return 'Code de vérification invalide';
      case 'invalid-verification-id':
        return 'ID de vérification invalide';
      case 'network-request-failed':
        return 'Erreur de réseau. Vérifiez votre connexion internet';
      default:
        return 'Erreur de connexion';
    }
  }
}