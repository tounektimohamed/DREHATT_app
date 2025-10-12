import 'dart:typed_data';

import 'package:DREHATT_app/screens2/homepage2.dart';
import 'package:DREHATT_app/screens2/users/formreclamation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'package:DREHATT_app/screens2/users/Claim.dart';

class ClaimsListPage extends StatefulWidget {
  @override
  _ClaimsListPageState createState() => _ClaimsListPageState();
}

class _ClaimsListPageState extends State<ClaimsListPage> {
  String _searchQuery = '';
  String _filterStatus = 'all';
  String _filterCategory = 'all';
  final List<String> _statusOptions = ['all', 'pending', 'in_progress', 'resolved', 'rejected'];
  final List<String> _categoryOptions = ['all', 'infrastructure', 'environment', 'safety', 'general'];

  // Méthode pour décoder et redimensionner l'image base64
  Widget _buildBase64Image(String base64String, {double width = 100, double height = 100}) {
    try {
      if (base64String.isEmpty) {
        return Image.asset(
          'assets/images/placeholder.png',
          width: width,
          height: height,
          fit: BoxFit.cover,
        );
      }

      // Décoder l'image base64
      final bytes = base64.decode(base64String);
      
      // Redimensionner l'image pour optimiser les performances
      final originalImage = img.decodeImage(bytes);
      if (originalImage != null) {
        final resizedImage = img.copyResize(originalImage, width: width.toInt());
        final resizedBytes = img.encodeJpg(resizedImage, quality: 80);
        return Image.memory(
          Uint8List.fromList(resizedBytes),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorImage(width, height);
          },
        );
      }
      
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage(width, height);
        },
      );
    } catch (e) {
      return _buildErrorImage(width, height);
    }
  }

  Widget _buildErrorImage(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Icon(Icons.error, color: Colors.red),
    );
  }

  Future<void> _deleteClaim(BuildContext context, String claimId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer cette réclamation ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('claims').doc(claimId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Réclamation supprimée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateClaimStatus(String claimId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('claims').doc(claimId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  void _openMap(BuildContext context, double latitude, double longitude) {
    final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    _launchURL(context, url);
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir la carte: $e')),
      );
    }
  }

  void _showImageDialog(BuildContext context, String base64Image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text('Image de la réclamation'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Expanded(
                  child: _buildBase64Image(base64Image, width: double.infinity, height: double.infinity),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'in_progress':
        color = Colors.blue;
        break;
      case 'resolved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des Réclamations'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ClaimFormPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Rechercher...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterStatus,
                        items: _statusOptions.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status == 'all' ? 'Tous les statuts' : status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _filterStatus = value!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Statut',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterCategory,
                        items: _categoryOptions.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category == 'all' ? 'Toutes catégories' : category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _filterCategory = value!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Catégorie',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('claims').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final claims = snapshot.data!.docs.map((doc) => Claim.fromFirestore(doc)).toList();

                // Appliquer les filtres
                final filteredClaims = claims.where((claim) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      claim.title.toLowerCase().contains(_searchQuery) ||
                      claim.content.toLowerCase().contains(_searchQuery);
                  
                  final matchesStatus = _filterStatus == 'all' || claim.status == _filterStatus;
                  final matchesCategory = _filterCategory == 'all' || claim.category == _filterCategory;

                  return matchesSearch && matchesStatus && matchesCategory;
                }).toList();

                if (filteredClaims.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucune réclamation trouvée',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredClaims.length,
                  itemBuilder: (context, index) {
                    Claim claim = filteredClaims[index];

                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    claim.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                _buildStatusChip(claim.status),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text('Description: ${claim.content}'),
                            SizedBox(height: 4),
                            Text('Téléphone: ${claim.phone}'),
                            SizedBox(height: 4),
                            Text('Email: ${claim.email}'),
                            SizedBox(height: 4),
                            if (claim.position != null)
                              Text(
                                'Localisation: ${claim.position!.latitude.toStringAsFixed(4)}, ${claim.position!.longitude.toStringAsFixed(4)}',
                              ),
                            SizedBox(height: 4),
                            Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(claim.timestamp.toDate())}'),
                            SizedBox(height: 8),
                            
                            // Image cliquable
                            GestureDetector(
                              onTap: () => _showImageDialog(context, claim.imageBase64),
                              child: _buildBase64Image(claim.imageBase64, width: 150, height: 100),
                            ),
                            
                            SizedBox(height: 8),
                            ButtonBar(
                              alignment: MainAxisAlignment.start,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteClaim(context, claim.id),
                                  tooltip: 'Supprimer',
                                ),
                                if (claim.position != null)
                                  IconButton(
                                    icon: Icon(Icons.map, color: Colors.blue),
                                    onPressed: () => _openMap(context, claim.position!.latitude, claim.position!.longitude),
                                    tooltip: 'Voir sur la carte',
                                  ),
                                PopupMenuButton<String>(
                                  onSelected: (newStatus) => _updateClaimStatus(claim.id, newStatus),
                                  itemBuilder: (BuildContext context) {
                                    return _statusOptions.where((status) => status != 'all').map((status) {
                                      return PopupMenuItem(
                                        value: status,
                                        child: Text('Marquer comme $status'),
                                      );
                                    }).toList();
                                  },
                                  icon: Icon(Icons.more_vert),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}