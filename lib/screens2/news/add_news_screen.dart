import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddNewsScreen extends StatefulWidget {
  const AddNewsScreen({Key? key}) : super(key: key);

  @override
  _AddNewsScreenState createState() => _AddNewsScreenState();
}

class _AddNewsScreenState extends State<AddNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _authorController = TextEditingController(); // Nouveau champ pour le nom de l'auteur
  bool isLoading = false;

  Future<void> _submitNews() async {
    if (_formKey.currentState!.validate()) {
      String title = _titleController.text;
      String content = _contentController.text;
      String author = _authorController.text.isNotEmpty 
          ? _authorController.text 
          : 'Anonymous'; // Valeur par défaut si le champ est vide

      setState(() {
        isLoading = true;
      });

      try {
        await FirebaseFirestore.instance.collection('news').add({
          'title': title,
          'content': content,
          'author': author, // Utilise le nom saisi par l'utilisateur
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color.fromARGB(255, 7, 83, 96),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
            content: Text(
              'Actualité ajoutée avec succès',
            ),
          ),
        );

        // Réinitialiser les champs après l'envoi réussi
        _titleController.clear();
        _contentController.clear();
        _authorController.clear();
      } catch (e) {
        print('Erreur lors de l\'ajout de l\'actualité: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
            content: Text(
              'Échec de l\'ajout de l\'actualité',
            ),
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ajouter une actualité',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(35, 20, 35, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Champ Titre
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titre',
                  labelStyle: GoogleFonts.roboto(
                    color: const Color.fromARGB(255, 16, 15, 15),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Veuillez saisir un titre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Champ Auteur (optionnel)
              TextFormField(
                controller: _authorController,
                decoration: InputDecoration(
                  labelText: 'Votre nom (optionnel)',
                  labelStyle: GoogleFonts.roboto(
                    color: const Color.fromARGB(255, 16, 15, 15),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Champ Contenu
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Contenu',
                  labelStyle: GoogleFonts.roboto(
                    color: const Color.fromARGB(255, 16, 15, 15),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Veuillez saisir le contenu';
                  }
                  return null;
                },
                maxLines: 5,
              ),
              const SizedBox(height: 30),
              // Bouton d'envoi
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitNews,
                  style: ButtonStyle(
                    elevation: MaterialStateProperty.all(2),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        return Theme.of(context).colorScheme.primary;
                      },
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          'Publier',
                          style: GoogleFonts.roboto(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}