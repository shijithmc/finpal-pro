import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/widgets/amount_input_field.dart';
import '../../accounts/application/providers.dart';
import '../../accounts/domain/account.dart';
import '../../ai_scan/application/providers.dart';
import '../../ai_scan/domain/scan_prefill.dart';
import '../../categories/application/providers.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_picker_widget.dart';
import '../application/providers.dart';
import 'templates_page.dart' show TemplateData;

class AddTransactionPage extends ConsumerStatefulWidget {
  /// Loads an existing ledger entry for editing when provided.
  final String? transactionId;

  /// Pre-fills the form from a bookmark template when provided.
  final TemplateData? template;

  /// Pre-fills the form from an AI bill scan when provided (PBI-016).
  /// The user reviews and saves — the scan never writes the ledger itself.
  final ScanPrefillData? scanPrefill;

  const AddTransactionPage({
    super.key,
    this.transactionId,
    this.template,
    this.scanPrefill,
  });

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
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
  bool _initializing = false;
  bool _transactionLoaded = false;
  List<Account> _originalAccounts = [];
  String? _error;

  /// True while the category shown was picked by AI and not yet confirmed
  /// or changed by the user (drives the "AI" badge).
  bool _aiCategorySuggested = false;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    if (t != null) {
      _type = t.type;
      _amount = t.amountSubunits / 100.0;
      _debitAccountId = t.debitAccountId;
      _creditAccountId = t.creditAccountId;
      _descController.text = t.description;
      _notesController.text = t.notes ?? '';
    }

    final s = widget.scanPrefill;
    if (s != null) {
      _type = TransactionType.expense;
      if (s.amountPaise != null) _amount = s.amountPaise! / 100.0;
      if (s.merchant != null) _descController.text = s.merchant!;
      if (s.billDate != null) _date = s.billDate!;
      if (s.categoryId != null) _loadScanCategory(s.categoryId!);
    }

    final initialIndex = [
      TransactionType.expense,
      TransactionType.income,
      TransactionType.transfer,
    ].indexOf(_type).clamp(0, 2);

    _tabController =
        TabController(length: 3, vsync: this, initialIndex: initialIndex)
          ..addListener(() {
            final type = [
              TransactionType.expense,
              TransactionType.income,
              TransactionType.transfer,
            ][_tabController.index];
            if (_type == type) return;
            setState(() {
              _type = type;
              _category = null;
              _aiCategorySuggested = false;
            });
          });
    if (widget.transactionId != null) {
      _initializing = true;
      _loadTransaction();
    }
  }

  Future<void> _loadTransaction() async {
    try {
      final entry = await ref
          .read(transactionRepositoryProvider)
          .findById(widget.transactionId!);
      if (entry == null) throw StateError('Transaction not found');
      final category = entry.categoryId == null
          ? null
          : await ref
                .read(categoryRepositoryProvider)
                .findById(entry.categoryId!);
      final originals = <Account>[];
      for (final id in {entry.debitAccountId, entry.creditAccountId}) {
        final account = await ref.read(accountRepositoryProvider).findById(id);
        if (account != null) originals.add(account);
      }
      if (!mounted) return;
      setState(() {
        _type = entry.type;
        _tabController.index = [
          TransactionType.expense,
          TransactionType.income,
          TransactionType.transfer,
        ].indexOf(_type);
        _amount = entry.amount.asMajorUnits;
        _debitAccountId = entry.debitAccountId;
        _creditAccountId = entry.creditAccountId;
        _category = category;
        _date = entry.transactionDate;
        _descController.text = entry.description;
        _notesController.text = entry.notes ?? '';
        _originalAccounts = originals;
        _transactionLoaded = true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Resolves the AI-selected category id against the local category list.
  /// A stale or unknown id silently leaves the picker empty.
  Future<void> _loadScanCategory(String categoryId) async {
    final category = await ref
        .read(categoryRepositoryProvider)
        .findById(categoryId);
    if (mounted && category != null) {
      setState(() {
        _category = category;
        _aiCategorySuggested = true;
      });
    }
  }

  /// Reports which AI-extracted fields the user corrected before saving —
  /// fire-and-forget accuracy telemetry (issue #64 AC).
  void _sendScanFeedback(int amountSubunits) {
    final s = widget.scanPrefill;
    if (s == null) return;
    final correctedFields = <String>[
      if (s.amountPaise != null && amountSubunits != s.amountPaise) 'amount',
      if ((s.merchant ?? '') != _descController.text.trim()) 'merchant',
      if (s.billDate != null && !_isSameDay(_date, s.billDate!)) 'date',
      if (_category?.id != s.categoryId) 'category',
    ];
    if (correctedFields.isNotEmpty) {
      unawaited(
        ref
            .read(scanServiceProvider)
            .sendFeedback(scanId: s.scanId, correctedFields: correctedFields),
      );
    }
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate() async {
    final earliest = DateTime(2000);
    final latest = DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _date.isBefore(earliest) ? _date : earliest,
      lastDate: _date.isAfter(latest) ? _date : latest,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // Expense and income use one real account; the second FK mirrors it.
    if (_type == TransactionType.expense) _creditAccountId = _debitAccountId;
    if (_type == TransactionType.income) _debitAccountId = _creditAccountId;
    if (_debitAccountId == null || _creditAccountId == null) {
      setState(() => _error = 'Please select account(s)');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final amountSubunits = (_amount * AppConstants.currencySubunits).round();
      final params = CreateTransactionParams(
        type: _type,
        amountSubunits: amountSubunits,
        debitAccountId: _debitAccountId!,
        creditAccountId: _creditAccountId!,
        categoryId: _type == TransactionType.transfer ? null : _category?.id,
        description: _descController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        date: _date,
      );
      if (widget.transactionId == null) {
        await ref.read(createTransactionProvider)(params);
      } else {
        await ref.read(updateTransactionProvider)(
          widget.transactionId!,
          params,
        );
      }
      _sendScanFeedback(amountSubunits);
      if (mounted) context.pop();
    } on ArgumentError catch (e) {
      if (mounted) setState(() => _error = e.message.toString());
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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
        title: Text(
          widget.transactionId == null ? 'Add Transaction' : 'Edit Transaction',
        ),
        actions: [
          if (widget.transactionId == null)
            IconButton(
              icon: const Icon(Icons.document_scanner_outlined),
              tooltip: 'Scan a bill',
              onPressed: () => context.pushReplacement('/scan'),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
            Tab(text: 'Transfer'),
          ],
        ),
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : widget.transactionId != null && !_transactionLoaded
          ? Center(child: Text(_error ?? 'Transaction not found'))
          : accountsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (accounts) => _buildForm([
                ...accounts,
                for (final original in _originalAccounts)
                  if (!accounts.any((a) => a.id == original.id)) original,
              ], theme),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed:
                _loading ||
                    _initializing ||
                    !accountsAsync.hasValue ||
                    (widget.transactionId != null && !_transactionLoaded)
                ? null
                : _save,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
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
            // Amount (initialValue shows template / scan prefills)
            AmountInputField(
              initialValue: _amount,
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
                title: Row(
                  children: [
                    Flexible(child: Text(_category?.name ?? 'Select Category')),
                    if (_aiCategorySuggested) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Category suggested by AI — tap to change',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'AI',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  _aiCategorySuggested
                      ? 'AI suggestion — tap to confirm or change'
                      : 'Tap to choose',
                ),
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
                    setState(() {
                      _category = selected;
                      // Any manual pick confirms or replaces the AI choice.
                      _aiCategorySuggested = false;
                    });
                  }
                },
                tileColor: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
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
