import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FirebaseConfigErrorScreen extends StatelessWidget {
  final String errorMessage;

  const FirebaseConfigErrorScreen({
    super.key,
    required this.errorMessage,
  });

  Future<void> _openFirebaseConsole() async {
    final url = Uri.parse(
      'https://console.firebase.google.com/project/event-sphere-f3f91/settings/general',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Firebase Configuration Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const Text(
                'To fix this:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Go to Firebase Console (click button below)\n'
                '2. Scroll to "Your apps" section\n'
                '3. Click on your Android app (or create one)\n'
                '4. Download google-services.json\n'
                '5. Extract values and update lib/firebase_options.dart',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _openFirebaseConsole,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Firebase Console'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Or install Firebase CLI and run:\n'
                'flutterfire configure',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

