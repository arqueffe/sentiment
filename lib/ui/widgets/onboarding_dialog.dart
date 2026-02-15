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
            Text('A private journal that stays on your phone.'),
            SizedBox(height: 12),
            Text('• Write entries anytime and revisit them later.'),
            SizedBox(height: 6),
            Text('• Track how you feel before and after writing.'),
            SizedBox(height: 6),
            Text(
              '• Emotion AI classification is active: the app reads the emotional tone of your text directly on-device and summarizes patterns over time.',
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
