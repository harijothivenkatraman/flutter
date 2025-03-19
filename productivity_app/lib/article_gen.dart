import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:flutter/services.dart'; // For rootBundle

class ArticleGeneratorPage extends StatefulWidget {
  @override
  _ArticleGeneratorPageState createState() => _ArticleGeneratorPageState();
}

class _ArticleGeneratorPageState extends State<ArticleGeneratorPage> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _articleController = TextEditingController();
  bool _isLoading = false;

  // OpenRouter API Key
  final String apiKey = "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"; // Replace with your API key
  final String apiUrl = "https://openrouter.ai/api/v1/chat/completions";

  Future<void> _generateArticle() async {
    if (_topicController.text.isEmpty) return;

    setState(() => _isLoading = true);

    final Map<String, dynamic> requestData = {
      "model": "openai/gpt-3.5-turbo",
      "messages": [
        {"role": "system", "content": "You are a helpful assistant."},
        {
          "role": "user",
          "content": "Write a detailed article about ${_topicController.text}."
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey("choices") && responseData["choices"].isNotEmpty) {
          String generatedArticle = responseData["choices"][0]["message"]["content"];
          setState(() {
            _articleController.text = generatedArticle;
          });
        } else {
          throw Exception("Invalid response format: No choices found");
        }
      } else {
        throw Exception("Error: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      print("Failed to generate article: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to generate article. Please try again.")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadArticleAsPdf() async {
    if (_articleController.text.isEmpty) return;

    final pdf = pw.Document();
    final font = await rootBundle.load("assets/fonts/Roboto-Regular.ttf"); // Load a custom font
    final ttf = pw.Font.ttf(font);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text(
              _articleController.text,
              style: pw.TextStyle(font: ttf, fontSize: 12), // Use the custom font
            ),
          );
        },
      ),
    );

    // Get the local storage directory
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/article_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(filePath);

    // Save the PDF file
    await file.writeAsBytes(await pdf.save());

    // Show a Snackbar with the file path
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("PDF saved to: $filePath"),
        action: SnackBarAction(
          label: "Open",
          onPressed: () async {
            try {
              await OpenFile.open(filePath);
            } catch (e) {
              print("Failed to open file: $e");
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to open the PDF file.")));
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Article Generator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Topic Input
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                labelText: 'Enter a topic',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            // Generate Article Button
            ElevatedButton(
              onPressed: _generateArticle,
              child: Text('Generate Article'),
            ),
            SizedBox(height: 20),
            // Generated Article
            Expanded(
              child: TextField(
                controller: _articleController,
                maxLines: null,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Generated article will appear here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 10),
            // Download as PDF Button
            ElevatedButton(
              onPressed: _downloadArticleAsPdf,
              child: Text('Download as PDF'),
            ),
          ],
        ),
      ),
    );
  }
}