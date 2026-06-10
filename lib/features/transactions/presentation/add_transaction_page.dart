import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/widgets/amount_input_field.dart';
import '../../accounts/application/providers.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_picker_widget.dart';
import '../application/providers.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key});

  @override
  ConsumerState<AddTransactionPage> createState() =>
      _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  double _amount = 0;
  String? _debitAccountId;
  String? _creditAccountId;
  Category? _category;
  DateTime _date = DateTime.now();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        setState(() {
          _type = [
            TransactionType.expense,
            TransactionType.income,
            TransactionType.transfer,
          ][_tabController.index];
          _category = null;
        });
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_debitAccountId == null || _creditAccountId == null) {
      setState(() => _error = 'Please select account(s)');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final create = ref.read(createTransactionProvider);
      final amountSubunits =
          (_amount * AppConstants.currencySubunits).round();
      await create(CreateTransactionParams(
        type: _type,
        amountSubunits: amountSubunits,
        debitAccountId: _debitAccountId!,
        creditAccountId: _creditAccountId!,
        categoryId: _category?.id,
        description: _descController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        date: _date,
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
    final accountsAsync = ref.watch(accountsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
            Tab(text: 'Transfer'),
          ],
        ),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accounts) => _buildForm(accounts, theme),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: Colors.white))
                : const Text('Save'),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(List<Account> accounts, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount
            AmountInputField(
              onChanged: (v) => _amount = v,
            ),
            const SizedBox(height: 16),

            // Account pickers
            if (_type == TransactionType.expense ||
                _type == TransactionType.transfer) ...[
              _AccountDropdown(
                label: _type == TransactionType.transfer
                    ? 'From Account'
                    : 'Account',
                accounts: accounts,
                selectedId: _debitAccountId,
                onChanged: (id) => setState(() => _debitAccountId = id),
              ),
              const SizedBox(height: 12),
            ],
            if (_type == TransactionType.income) ...[
              _AccountDropdown(
                label: 'Account',
                accounts: accounts,
                selectedId: _creditAccountId,
                onChanged: (id) {
                  setState(() {
                    _creditAccountId = id;
                    _debitAccountId = id; // income: same account for both
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
            if (_type == TransactionType.transfer) ...[
              _AccountDropdown(
                label: 'To Account',
                accounts: accounts,
                selectedId: _creditAccountId,
                onChanged: (id) => setState(() => _creditAccountId = id),
              ),
              const SizedBox(height: 12),
            ],

            // Category
            if (_type != TransactionType.transfer) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.label_outline),
                title: Text(_category?.name ?? 'Select Category'),
                subtitle: const Text('Tap to choose'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final selected = await showCategoryPicker(
                    context,
                    type: _type == TransactionType.expense
                        ? CategoryType.expense
                        : CategoryType.income,
                    selectedId: _category?.id,
                  );
                  if (selected != null || _category != null) {
                    setState(() => _category = selected);
                  }
                },
                tileColor: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(height: 12),
            ],

            // Description
            TextFormField(
              controller: _descController,
              maxLength: AppConstants.maxDescriptionLength,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(DateFormat('dd MMM yyyy').format(_date)),
              subtitle: const Text('Transaction date'),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDate,
              tileColor: theme.colorScheme.surfaceContainerHighest,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 12),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLength: AppConstants.maxNotesLength,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  final String label;
  final List<Account> accounts;
  final String? selectedId;
  final void Function(String?) onChanged;

  const _AccountDropdown({
    required this.label,
    required this.accounts,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: selectedId,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: accounts
          .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Please select an account' : null,
    );
  }
}
