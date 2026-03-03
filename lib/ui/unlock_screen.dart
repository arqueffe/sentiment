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
  final _confirmPasswordController = TextEditingController();
  bool _enableBiometric = false;
  bool _isSubmitting = false;
  bool _didPrecacheLogo = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheLogo) {
      return;
    }
    _didPrecacheLogo = true;
    precacheImage(const AssetImage('assets/images/logo.apng'), context);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authState = ref.read(authControllerProvider);
    final isSetup = authState.hasPassword;
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _error = 'Password cannot be empty';
      });
      return;
    }

    if (!isSetup) {
      final confirmPassword = _confirmPasswordController.text.trim();
      if (confirmPassword.isEmpty) {
        setState(() {
          _error = 'Please confirm your password';
        });
        return;
      }
      if (confirmPassword != password) {
        setState(() {
          _error = 'Passwords do not match';
        });
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const logoSize = 200.0;
    final logoCacheSize = (logoSize * MediaQuery.devicePixelRatioOf(context))
        .round();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.apng',
                    width: logoSize,
                    height: logoSize,
                    cacheWidth: logoCacheSize,
                    cacheHeight: logoCacheSize,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSetup
                                    ? Icons.lock_open_rounded
                                    : Icons.lock_rounded,
                                color: colorScheme.onPrimaryContainer,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            isSetup
                                ? 'Unlock your journal'
                                : 'Create your lock',
                            style: textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isSetup
                                ? 'Your entries stay private and protected on this device.'
                                : 'Set a password to encrypt your journal on this device.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: isSetup
                                ? TextInputAction.done
                                : TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.password_rounded),
                            ),
                            onSubmitted: (_) {
                              if (isSetup) {
                                _submit();
                              }
                            },
                          ),
                          if (!isSetup) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon: Icon(Icons.password_rounded),
                              ),
                              onSubmitted: (_) => _submit(),
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (!isSetup)
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: _enableBiometric,
                              onChanged: (value) {
                                setState(() {
                                  _enableBiometric = value;
                                });
                              },
                              title: const Text(
                                'Enable biometrics on this device',
                              ),
                              subtitle: const Text('Optional quick unlock'),
                            ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isSubmitting ? null : _submit,
                              icon: _isSubmitting
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.onPrimary,
                                      ),
                                    )
                                  : Icon(
                                      isSetup
                                          ? Icons.lock_open_rounded
                                          : Icons.lock_rounded,
                                    ),
                              label: Text(isSetup ? 'Unlock' : 'Create lock'),
                            ),
                          ),
                          if (canBiometric) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isSubmitting
                                    ? null
                                    : _unlockWithBiometrics,
                                icon: const Icon(Icons.fingerprint_rounded),
                                label: const Text('Use biometrics'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
