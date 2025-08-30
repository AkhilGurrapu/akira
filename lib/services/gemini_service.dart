import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart';

class GeminiService {
  final String _projectId = dotenv.env['GOOGLE_PROJECT_ID']!;
  final String _region = dotenv.env['VERTEX_AI_REGION']!;
  // Match goldsarva setup: Gemini 2.5 Flash Image Preview
  final String _model = 'gemini-2.5-flash-image-preview';

  String get _endpointHost {
    final regionLower = _region.toLowerCase().trim();
    if (regionLower.isEmpty) {
      throw StateError('VERTEX_AI_REGION is empty. Set it to a region or "global".');
    }
    // goldsarva works with global; for global use the non-regional host
    if (regionLower == 'global') {
      return 'aiplatform.googleapis.com';
    }
    return '$_region-aiplatform.googleapis.com';
  }

  Future<AuthClient> _getAuthClient() async {
    final jsonCredentials =
        await rootBundle.loadString('service-account-key.json');
    final credentials = ServiceAccountCredentials.fromJson(
      json.decode(jsonCredentials),
    );
    final scopes = ['https://www.googleapis.com/auth/cloud-platform'];
    return await clientViaServiceAccount(credentials, scopes);
  }

  Future<String> sendRequest(
      File image, String clothingAssetPath, String prompt) async {
    final authClient = await _getAuthClient();
    final url = Uri.parse(
        'https://${_endpointHost}/v1/projects/$_projectId/locations/$_region/publishers/google/models/$_model:generateContent');

    final imageBytes = await image.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final clothingBytes = await rootBundle.load(clothingAssetPath);
    final base64Clothing = base64Encode(clothingBytes.buffer.asUint8List());

    final requestBody = json.encode({
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": prompt},
            {
              "inlineData": {
                "mimeType": "image/jpeg",
                "data": base64Image,
              }
            },
            {
              "inlineData": {
                "mimeType": "image/jpeg",
                "data": base64Clothing,
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "maxOutputTokens": 32768,
        "temperature": 1,
        "topP": 0.95,
        "responseModalities": ["TEXT", "IMAGE"]
      },
      "safetySettings": [
        {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "OFF"},
        {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "OFF"},
        {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "OFF"},
        {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "OFF"},
        {"category": "HARM_CATEGORY_IMAGE_HATE", "threshold": "OFF"},
        {"category": "HARM_CATEGORY_IMAGE_DANGEROUS_CONTENT", "threshold": "OFF"},
        {"category": "HARM_CATEGORY_IMAGE_HARASSMENT", "threshold": "OFF"},
        {"category": "HARM_CATEGORY_IMAGE_SEXUALLY_EXPLICIT", "threshold": "OFF"}
      ]
    });

    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to send request to Gemini API: ${response.body}');
    }
  }
}
