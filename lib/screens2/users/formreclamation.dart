import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ClaimFormPage extends StatefulWidget {
  @override
  _ClaimFormPageState createState() => _ClaimFormPageState();
}

class _ClaimFormPageState extends State<ClaimFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  XFile? _image;
  String _imageBase64 = ''; // Changé pour stocker base64
  Position? _position;
  bool _isLoading = false;
  String _selectedCategory = 'general';
  bool _locationLoading = false;

  final List<String> _categories = [
    'infrastructure',
    'environment', 
    'safety',
    'general'
  ];

  // Méthode pour convertir l'image en base64 avec compression
  Future<String> _convertImageToBase64(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      // Compresser l'image
      final originalImage = img.decodeImage(bytes);
      if (originalImage != null) {
        // Redimensionner l'image si elle est trop grande
        final maxWidth = 800;
        final resizedImage = originalImage.width > maxWidth 
            ? img.copyResize(originalImage, width: maxWidth)
            : originalImage;
            
        final compressedBytes = img.encodeJpg(resizedImage, quality: 75);
        return base64.encode(compressedBytes);
      }
      
      return base64.encode(bytes);
    } catch (e) {
      throw 'Erreur lors du traitement de l\'image: $e';
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _isLoading = true;
        });

        // Convertir l'image en base64
        final base64String = await _convertImageToBase64(pickedFile);
        
        setState(() {
          _image = pickedFile;
          _imageBase64 = base64String;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _isLoading = true;
        });

        final base64String = await _convertImageToBase64(pickedFile);
        
        setState(() {
          _image = pickedFile;
          _imageBase64 = base64String;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la prise de photo: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _locationLoading = true;
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Vérifier si le service de localisation est activé
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veuillez activer la localisation')),
        );
        return;
      }

      // Vérifier les permissions
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permissions de localisation refusées')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Les permissions de localisation sont définitivement refusées. Activez-les dans les paramètres.')),
        );
        return;
      }

      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      setState(() {
        _position = position;
        _locationLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Localisation obtenue avec succès')),
      );
    } catch (e) {
      setState(() {
        _locationLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'obtention de la localisation: $e')),
      );
    }
  }

  Future<void> _submitClaim() async {
    if (_formKey.currentState!.validate()) {
      if (_imageBase64.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veuillez ajouter une photo')),
        );
        return;
      }

      if (_position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veuillez obtenir votre localisation')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw 'Utilisateur non connecté';
        }

        // Sauvegarder la réclamation dans Firestore
        await FirebaseFirestore.instance.collection('claims').add({
          'userId': user.uid,
          'title': _titleController.text,
          'content': _contentController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
          'imageBase64': _imageBase64, // Sauvegarde en base64
          'position': GeoPoint(_position!.latitude, _position!.longitude),
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
          'category': _selectedCategory,
          'userEmail': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Réclamation soumise avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // Réinitialiser le formulaire
        _formKey.currentState!.reset();
        setState(() {
          _image = null;
          _imageBase64 = '';
          _position = null;
          _selectedCategory = 'general';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la soumission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImagePreview() {
    if (_imageBase64.isEmpty) {
      return Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo, size: 40, color: Colors.grey),
            Text('Aucune image', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.memory(
            base64.decode(_imageBase64),
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: CircleAvatar(
            radius: 12,
            backgroundColor: Colors.red,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.close, size: 12, color: Colors.white),
              onPressed: () {
                setState(() {
                  _image = null;
                  _imageBase64 = '';
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nouvelle Réclamation'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Catégorie
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Catégorie',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez sélectionner une catégorie';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Titre
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Titre *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un titre';
                        }
                        if (value.length < 5) {
                          return 'Le titre doit contenir au moins 5 caractères';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une description';
                        }
                        if (value.length < 10) {
                          return 'La description doit contenir au moins 10 caractères';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Téléphone
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Téléphone *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre numéro de téléphone';
                        }
                        if (!RegExp(r'^[0-9+\-\s()]{8,}$').hasMatch(value)) {
                          return 'Veuillez entrer un numéro de téléphone valide';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre email';
                        } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Veuillez entrer une adresse email valide';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Section Image
                    Text('Photo *', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    _buildImagePreview(),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: Icon(Icons.photo_library),
                            label: Text('Galerie'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _takePhoto,
                            icon: Icon(Icons.camera_alt),
                            label: Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Section Localisation
                    Text('Localisation *', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _locationLoading ? null : _getCurrentLocation,
                      icon: _locationLoading 
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.location_on),
                      label: Text(_locationLoading ? 'Obtention...' : 'Obtenir la localisation'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    SizedBox(height: 8),
                    _position == null
                        ? Text(
                            'Aucune localisation sélectionnée',
                            style: TextStyle(color: Colors.red),
                          )
                        : Card(
                            color: Colors.green[50],
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Localisation obtenue:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text('Latitude: ${_position!.latitude.toStringAsFixed(6)}'),
                                  Text('Longitude: ${_position!.longitude.toStringAsFixed(6)}'),
                                  Text('Précision: ${_position!.accuracy?.toStringAsFixed(2) ?? 'N/A'} m'),
                                ],
                              ),
                            ),
                          ),
                    SizedBox(height: 24),

                    // Bouton de soumission
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitClaim,
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Soumettre la Réclamation'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}