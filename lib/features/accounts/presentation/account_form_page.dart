import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/widgets/amount_input_field.dart';
import '../application/providers.dart';

class AccountFormPage extends ConsumerStatefulWidget {
  final String? accountId; // null = create, non-null = edit

  const AccountFormPage({super.key, this.accountId});

  @override
  ConsumerState<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends ConsumerState<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  AccountType _type = AccountType.cash;
  double _openingBalance = 0;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final create = ref.read(createAccountProvider);
      await create(CreateAccountParams(
        name: _nameController.text.trim(),
        type: _type,
        openingBalanceMajor: _openingBalance,
      ));
      if (mounted) context.pop();
    } on ArgumentError catch (e) {
      setState(() => _error = e.message.toString());
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
      appBar: AppBar(
        title: Text(widget.accountId == null ? 'New Account' : 'Edit Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AccountType>(
                // ignore: deprecated_member_use
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(),
                ),
                items: AccountType.values.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(_typeLabel(t)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              AmountInputField(
                labelText: 'Opening Balance',
                initialValue: _openingBalance,
                onChanged: (v) => _openingBalance = v,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(AccountType t) => switch (t) {
        AccountType.cash => 'Cash',
        AccountType.bank => 'Bank Account',
        AccountType.savings => 'Savings',
        AccountType.creditCard => 'Credit Card',
        AccountType.investment => 'Investment',
      };
}
