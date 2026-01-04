#!/usr/bin/env dart
// Helper script to extract Firebase config from google-services.json
// Usage: dart scripts/extract_firebase_config.dart path/to/google-services.json

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart scripts/extract_firebase_config.dart <path-to-google-services.json>');
    exit(1);
  }

  final file = File(args[0]);
  if (!file.existsSync()) {
    print('Error: File not found: ${args[0]}');
    exit(1);
  }

  try {
    final content = file.readAsStringSync();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final project = json['project_info'] as Map<String, dynamic>;
    final client = (json['client'] as List).first as Map<String, dynamic>;
    final apiKey = (client['api_key'] as List).first as Map<String, dynamic>;
    final appId = client['client_info'] as Map<String, dynamic>;

    print('\n=== Firebase Configuration ===\n');
    print('Project ID: ${project['project_id']}');
    print('Storage Bucket: ${project['storage_bucket']}');
    print('API Key: ${apiKey['current_key']}');
    print('App ID: ${appId['mobilesdk_app_id']}');
    print('Messaging Sender ID: ${project['project_number']}');
    print('\n=== Update lib/firebase_options.dart with these values ===\n');
  } catch (e) {
    print('Error parsing google-services.json: $e');
    exit(1);
  }
}

