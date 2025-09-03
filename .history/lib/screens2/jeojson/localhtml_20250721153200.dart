import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui' as ui;

class HtmlListPage extends StatefulWidget {
  @override
  _HtmlListPageState createState() => _HtmlListPageState();
}

class _HtmlListPageState extends State<HtmlListPage> {
  String htmlContentUrl = '';
  List<String> documentTitles = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDocumentTitles();
  }

  Future<void> _fetchDocumentTitles() async {
    setState(() => isLoading = true);
    try {
      final response =
          await http.get(Uri.parse('https://geotiif.vercel.app/pages'));
      if (response.statusCode == 200) {
        final List<dynamic> titles = json.decode(response.body);
        setState(() {
          documentTitles = titles.cast<String>();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load document titles');
      }
    } catch (e) {
      print('Error fetching document titles: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching document titles';
      });
    }
  }

  Future<void> _fetchHtmlContent(String title) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final response =
          await http.get(Uri.parse('https://geotiif.vercel.app/page/$title'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final String htmlContent = jsonResponse['content'];

        // Convertir le contenu HTML en URL data URI
        final dataUri = Uri.dataFromString(htmlContent, mimeType: 'text/html').toString();

        setState(() {
          htmlContentUrl = dataUri;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load HTML content');
      }
    } catch (e) {
      print('Error fetching HTML content: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching HTML content';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ne pas enregistrer la factory hors Web (sinon erreur)
    if (kIsWeb && htmlContentUrl.isNotEmpty) {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        'iframe',
        (int viewId) {
          final iframe = html.IFrameElement()
            ..width = '100%'
            ..height = '500'
            ..src = htmlContentUrl
            ..style.border = 'none';
          return iframe;
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des plans'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage.isNotEmpty)
              Center(
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else ...[
              Expanded(
                child: ListView.builder(
                  itemCount: documentTitles.length,
                  itemBuilder: (context, index) {
                    final title = documentTitles[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4.0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => _fetchHtmlContent(title),
                      ),
                    );
                  },
                ),
              ),
              if (kIsWeb && htmlContentUrl.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 500,
                  child: const HtmlElementView(viewType: 'iframe'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
