import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sentiment/state/providers.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _passwordController = TextEditingController();
  bool _enableBiometric = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _error = 'Password cannot be empty';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final authState = ref.read(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    bool success = false;
    if (authState.hasPassword) {
      success = await controller.unlockWithPassword(password);
    } else {
      await controller.createPassword(
        password,
        enableBiometric: _enableBiometric,
      );
      success = true;
    }

    if (!success) {
      setState(() {
        _error = 'Invalid password';
      });
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _unlockWithBiometrics() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.unlockWithBiometrics();
    if (!success) {
      setState(() {
        _error = 'Biometric unlock failed';
      });
    }
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final canBiometric = authState.canBiometric;
    final isSetup = authState.hasPassword;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                isSetup ? 'Unlock your journal' : 'Create your lock',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                isSetup
                    ? 'Your journal never leaves your phone.'
                    : 'Set a password to encrypt your journal.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Password'),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              if (!isSetup)
                SwitchListTile.adaptive(
                  value: _enableBiometric,
                  onChanged: (value) {
                    setState(() {
                      _enableBiometric = value;
                    });
                  },
                  title: const Text('Enable biometrics on this device'),
                  subtitle: const Text('Optional quick unlock'),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Text(isSetup ? 'Unlock' : 'Create'),
                ),
              ),
              if (canBiometric) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _unlockWithBiometrics,
                    child: const Text('Use biometrics'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
