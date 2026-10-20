import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptAiService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> captureReceipt() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    return photo != null ? File(photo.path) : null;
  }

  Future<Map<String, dynamic>?> parseReceiptWithAI(
    File imageFile,
    String apiKey,
  ) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3.8-flash', // Updated to the required model identifier
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: Schema.object(
            properties: {
              'title': Schema.string(
                description: 'Merchant or store name on the receipt',
              ),
              'amount': Schema.number(
                description: 'Final total amount paid',
              ),
              'category': Schema.enumString(
                enumValues: [
                  'Food',
                  'Transport',
                  'Utilities',
                  'Entertainment',
                  'Shopping',
                ],
                description: 'Best matching spending category',
              ),
            },
            requiredProperties: ['title', 'amount', 'category'],
          ),
        ),
      );

      final imageBytes = await imageFile.readAsBytes();

      const prompt = 'Extract the merchant name, total amount, and category from this receipt.';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await model.generateContent(content);
      final textResponse = response.text;

      if (textResponse != null && textResponse.isNotEmpty) {
        return jsonDecode(textResponse) as Map<String, dynamic>;
      }
    } catch (e) {
      print('AI Parsing Error: $e');
    }
    return null;
  }
}