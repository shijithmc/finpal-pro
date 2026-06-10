import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../application/providers.dart';

/// First-run page to set up a PIN. Requires entry + confirmation.
class SetupPinPage extends ConsumerStatefulWidget {
  final VoidCallback onSetupComplete;

  const SetupPinPage({super.key, required this.onSetupComplete});

  @override
  ConsumerState<SetupPinPage> createState() => _SetupPinPageState();
}

class _SetupPinPageState extends ConsumerState<SetupPinPage> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(securityServiceProvider)
          .setPin(_pinController.text.trim());
      if (mounted) widget.onSetupComplete();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Set Up PIN')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create a PIN to protect your financial data.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: AppConstants.maxPinLength,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.length < AppConstants.minPinLength) {
                    return 'PIN must be at least ${AppConstants.minPinLength} digits';
                  }
                  if (!RegExp(r'^\d+$').hasMatch(v)) {
                    return 'PIN must contain only digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: AppConstants.maxPinLength,
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v != _pinController.text) {
                    return 'PINs do not match';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Set PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
