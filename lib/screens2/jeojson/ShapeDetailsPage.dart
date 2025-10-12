import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ShapeDetailsPage extends StatefulWidget {
  final String shapeType;
  final double area;
  final List<Map<String, dynamic>> coordinates;

  ShapeDetailsPage({required this.shapeType, required this.area, required this.coordinates});

  @override
  _ShapeDetailsPageState createState() => _ShapeDetailsPageState();
}

class _ShapeDetailsPageState extends State<ShapeDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _cinController = TextEditingController();
  final _ownershipProofController = TextEditingController();
  final _areaController = TextEditingController();
  String? _selectedRegion;
  String? _selectedMunicipality;
  final _urbanPlanningModelController = TextEditingController();
  final _requestDateController = TextEditingController();

  final List<String> _regions = [
    'Délégation de Dhehiba (معتمدية الذهيبة)',
    'Délégation de Smar (معتمدية الصمار)',
    'Délégation de Bir Lahmar (معتمدية بئر الأحمر)',
    'Délégation de medenine Sud (معتمدية تطاوين الجنوبية)',
    'Délégation de medenine Nord (معتمدية تطاوين الشمالية)',
    'Délégation de Remada (معتمدية رمادة)',
    'Délégation de Ghomrassen (معتمدية غمراسن)',
    'ben mhira',
  ];

  final List<String> _municipalities = [
    'Dhehiba (معتمدية الذهيبة)',
    'Smar (معتمدية الصمار)',
    'Bir Lahjar (معتمدية بئر الأحمر)',
    'medenine Sud (معتمدية تطاوين الجنوبية)',
    'medenine Nord (معتمدية تطاوين الشمالية)',
    'Remada (معتمدية رمادة)',
    'Ghomrassen (معتمدية غمراسن)',
    'ben mhira',
  ];

  @override
  void initState() {
    super.initState();
    _areaController.text = widget.area.toStringAsFixed(2);
    _requestDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _cinController.dispose();
    _ownershipProofController.dispose();
    _areaController.dispose();
    _urbanPlanningModelController.dispose();
    _requestDateController.dispose();
    super.dispose();
  }

  void _saveToFirestore() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final area = double.tryParse(_areaController.text) ?? 0;

        if (area <= 0) {
          throw Exception('La superficie doit être un nombre valide et supérieur à 0.');
        }

        final data = {
          'name': _nameController.text,
          'firstName': _firstNameController.text,
          'cin': _cinController.text,
          'ownershipProof': _ownershipProofController.text,
          'area': area,
          'region': _selectedRegion,
          'municipality': _selectedMunicipality,
          'urbanPlanningModel': _urbanPlanningModelController.text,
          'requestDate': _requestDateController.text,
          'shapeType': widget.shapeType,
          'coordinates': widget.coordinates,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance.collection('shapes').add(data);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Forme enregistrée avec succès!'), backgroundColor: Colors.green),
        );

        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement des données: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _requestDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enregistrement - Permis de Bâtiment'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informations de la Forme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                        SizedBox(height: 8),
                        Text('Type: ${widget.shapeType}', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Superficie: ${widget.area.toStringAsFixed(2)} m²', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Points: ${widget.coordinates.length}', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'Prénom *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un prénom';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _cinController,
                  decoration: InputDecoration(
                    labelText: 'Numéro de carte d\'identité *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le numéro de carte d\'identité';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _ownershipProofController,
                  decoration: InputDecoration(
                    labelText: 'Type de preuve de propriété *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le type de preuve de propriété';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _areaController,
                  decoration: InputDecoration(
                    labelText: 'Superficie (m²) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.square_foot),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une superficie';
                    }
                    final number = double.tryParse(value);
                    if (number == null || number <= 0) {
                      return 'Veuillez entrer une superficie valide';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  decoration: InputDecoration(
                    labelText: 'Région *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map),
                  ),
                  items: _regions.map((region) {
                    return DropdownMenuItem(
                      value: region,
                      child: Text(region),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRegion = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une région';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedMunicipality,
                  decoration: InputDecoration(
                    labelText: 'Municipalité *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  items: _municipalities.map((municipality) {
                    return DropdownMenuItem(
                      value: municipality,
                      child: Text(municipality),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMunicipality = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une municipalité';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _urbanPlanningModelController,
                  decoration: InputDecoration(
                    labelText: 'Plan d\'aménagement urbain *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.architecture),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le plan d\'aménagement urbain';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _requestDateController,
                  decoration: InputDecoration(
                    labelText: 'Date de la demande *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_month),
                      onPressed: () => _selectDate(context),
                    ),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer la date de la demande';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      child: Text('Annuler'),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saveToFirestore,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                      child: Text('Enregistrer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}