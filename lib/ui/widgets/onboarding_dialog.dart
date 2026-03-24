import 'package:flutter/material.dart';

class OnboardingDialog extends StatelessWidget {
  const OnboardingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Welcome to Sentiment'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image(
                image: AssetImage('assets/images/logo.png'),
                width: 56,
                height: 56,
              ),
            ),
            SizedBox(height: 12),
            Text('This is a web demo version of Sentiment.'),
            SizedBox(height: 12),
            Text('What is included:'),
            SizedBox(height: 6),
            Text('• Create and revisit journal entries in your browser.'),
            SizedBox(height: 6),
            Text('• Track how you feel before and after writing.'),
            SizedBox(height: 6),
            Text(
              '• Emotion AI classification is active for sentence highlights and entry summaries.',
            ),
            SizedBox(height: 6),
            Text(
              '• The web classifier is a demo model and is less accurate than the mobile version.',
            ),
            SizedBox(height: 12),
            Text('What is not included in this demo:'),
            SizedBox(height: 6),
            Text('• Lock screen, password setup, and biometric unlock.'),
            SizedBox(height: 6),
            Text('• Import/export and other mobile-only capabilities.'),
            SizedBox(height: 6),
            Text(
              '• Entries are not encrypted and are not guaranteed to persist in this demo.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
