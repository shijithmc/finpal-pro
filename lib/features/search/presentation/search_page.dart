import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../accounts/domain/account.dart';
import '../../categories/application/providers.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_search_filter.dart';
import '../application/providers.dart';
import '../domain/search_statistics.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _query = TextEditingController();
  Timer? _debounce;
  bool _showStats = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final filter = ref.read(searchFilterProvider);
      ref.read(searchFilterProvider.notifier).state = filter.copyWith(
        query: query.trim(),
      );
    });
  }

  Future<void> _showFilters(
    List<Account> accounts,
    List<Category> categories,
  ) async {
    FocusScope.of(context).unfocus();
    final result = await showDialog<TransactionSearchFilter>(
      context: context,
      builder: (context) => _FiltersDialog(
        initial: ref.read(searchFilterProvider),
        accounts: accounts,
        categories: categories,
      ),
    );
    if (result != null && mounted) {
      _debounce?.cancel();
      ref.read(searchFilterProvider.notifier).state = result.copyWith(
        query: _query.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(searchFilterProvider);
    final results = ref.watch(filteredTransactionsProvider);
    final accountsAsync = ref.watch(searchAccountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final accounts = accountsAsync.valueOrNull ?? <Account>[];
    final categories = categoriesAsync.valueOrNull ?? <Category>[];
    final accountNames = {
      for (final account in accounts) account.id: account.name,
    };
    final categoryNames = {
      for (final category in categories) category.id: category.name,
    };
    void update(TransactionSearchFilter next) {
      ref.read(searchFilterProvider.notifier).state = next;
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Search Transactions')),
        body: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _query,
                      onChanged: _onQueryChanged,
                      maxLength: 200,
                      decoration: InputDecoration(
                        labelText: 'Search description or notes',
                        hintText: 'Search all history',
                        counterText: '',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _debounce?.cancel();
                            _query.clear();
                            update(filter.copyWith(query: ''));
                          },
                          icon: const Icon(Icons.clear),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed:
                              accountsAsync.hasValue && categoriesAsync.hasValue
                              ? () => _showFilters(accounts, categories)
                              : null,
                          icon: const Icon(Icons.tune),
                          label: const Text('Filters'),
                        ),
                        if (filter.from != null || filter.to != null)
                          InputChip(
                            label: Text(
                              _dateRangeLabel(filter.from, filter.to),
                            ),
                            onDeleted: () =>
                                update(filter.copyWith(clearDates: true)),
                          ),
                        for (final accountId in filter.accountIds)
                          InputChip(
                            label: Text(accountNames[accountId] ?? 'Account'),
                            onDeleted: () => update(
                              filter.copyWith(
                                accountIds: filter.accountIds.difference({
                                  accountId,
                                }),
                              ),
                            ),
                          ),
                        for (final categoryId in filter.categoryIds)
                          InputChip(
                            label: Text(
                              categoryNames[categoryId] ?? 'Category',
                            ),
                            onDeleted: () => update(
                              filter.copyWith(
                                categoryIds: filter.categoryIds.difference({
                                  categoryId,
                                }),
                              ),
                            ),
                          ),
                        if (filter.type != null)
                          InputChip(
                            label: Text(_typeLabel(filter.type!)),
                            onDeleted: () =>
                                update(filter.copyWith(clearType: true)),
                          ),
                        if (filter.minAmount != null ||
                            filter.maxAmount != null)
                          InputChip(
                            label: Text(
                              '${_money(filter.minAmount ?? 0)} – ${filter.maxAmount == null ? 'Any' : _money(filter.maxAmount!)}',
                            ),
                            onDeleted: () =>
                                update(filter.copyWith(clearAmount: true)),
                          ),
                      ],
                    ),
                    if (accountsAsync.hasError || categoriesAsync.hasError)
                      const Text('Could not load account or category filters.'),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: TabBar(
                onTap: (index) => setState(() => _showStats = index == 1),
                tabs: const [
                  Tab(text: 'Results'),
                  Tab(text: 'Stats'),
                ],
              ),
            ),
            ...results.when(
              // Hide old results and totals while the new filters are loading.
              skipLoadingOnReload: false,
              skipLoadingOnRefresh: false,
              loading: () => const <Widget>[
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (_, _) => <Widget>[
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Could not search transactions.'),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(filteredTransactionsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              data: (transactions) => <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _showStats
                        ? _SearchSummary(
                            transactions: transactions,
                            categoryNames: categoryNames,
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              '${transactions.length} matching transactions',
                            ),
                          ),
                  ),
                ),
                if (transactions.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No matching transactions')),
                  )
                else if (!_showStats)
                  SliverList.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final prefix = switch (tx.type) {
                        TransactionType.income => '+',
                        TransactionType.expense => '−',
                        TransactionType.transfer => '↔ ',
                      };
                      return ListTile(
                        title: Text(
                          tx.description.isEmpty
                              ? '(no description)'
                              : tx.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          [
                            DateFormat.yMMMd().format(tx.transactionDate),
                            if (tx.notes?.isNotEmpty ?? false) tx.notes!,
                          ].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text('$prefix${_money(tx.amount.subunits)}'),
                        onTap: () => context.push(
                          '/transactions/${Uri.encodeComponent(tx.id)}',
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSummary extends StatelessWidget {
  final List<FinTransaction> transactions;
  final Map<String, String> categoryNames;

  const _SearchSummary({
    required this.transactions,
    required this.categoryNames,
  });

  @override
  Widget build(BuildContext context) {
    final stats = SearchStatistics.fromTransactions(transactions);
    final entries = stats.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${transactions.length} matching transactions',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _Total(label: 'Income', value: stats.income),
                _Total(label: 'Expenses', value: stats.expense),
                _Total(label: 'Net', value: stats.net),
              ],
            ),
            if (stats.transfers > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Transfers: ${_money(stats.transfers)} (excluded from net)',
                ),
              ),
            if (entries.isNotEmpty)
              ExpansionTile(
                initiallyExpanded: true,
                tilePadding: EdgeInsets.zero,
                title: const Text('Expenses by category'),
                children: [
                  for (final entry in entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  categoryNames[entry.key] ?? 'Uncategorized',
                                ),
                              ),
                              Text(
                                '${_money(entry.value)} · ${(entry.value / stats.expense * 100).toStringAsFixed(0)}%',
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: entry.value / stats.expense,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String label;
  final int value;

  const _Total({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(
        _money(value),
        key: ValueKey('search-total-$label'),
        style: Theme.of(context).textTheme.titleSmall,
      ),
    ],
  );
}

class _FiltersDialog extends StatefulWidget {
  final TransactionSearchFilter initial;
  final List<Account> accounts;
  final List<Category> categories;

  const _FiltersDialog({
    required this.initial,
    required this.accounts,
    required this.categories,
  });

  @override
  State<_FiltersDialog> createState() => _FiltersDialogState();
}

class _FiltersDialogState extends State<_FiltersDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _minimum;
  late final TextEditingController _maximum;
  late Set<String> _accounts;
  late Set<String> _categories;
  late TransactionType? _type;
  DateTimeRange? _dates;

  @override
  void initState() {
    super.initState();
    final filter = widget.initial;
    _minimum = TextEditingController(text: _amountInput(filter.minAmount));
    _maximum = TextEditingController(text: _amountInput(filter.maxAmount));
    _accounts = filter.accountIds;
    _categories = filter.categoryIds;
    _type = filter.type;
    if (filter.from != null && filter.to != null) {
      _dates = DateTimeRange(start: filter.from!, end: filter.to!);
    }
  }

  @override
  void dispose() {
    _minimum.dispose();
    _maximum.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Search filters'),
    content: SizedBox(
      width: 400,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date range'),
                subtitle: Text(_dateRangeLabel(_dates?.start, _dates?.end)),
                trailing: _dates == null
                    ? const Icon(Icons.date_range)
                    : IconButton(
                        tooltip: 'Clear dates',
                        onPressed: () => setState(() => _dates = null),
                        icon: const Icon(Icons.clear),
                      ),
                onTap: () async {
                  final dates = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100, 12, 31),
                    initialDateRange: _dates,
                  );
                  if (dates != null && mounted) setState(() => _dates = dates);
                },
              ),
              _MultiSelectField(
                label: 'Accounts',
                allLabel: 'All accounts',
                options: {
                  for (final account in widget.accounts)
                    account.id:
                        '${account.name}${account.isArchived ? ' (archived)' : ''}',
                },
                selected: _accounts,
                onChanged: (value) => setState(() => _accounts = value),
              ),
              const SizedBox(height: 12),
              _MultiSelectField(
                label: 'Categories',
                allLabel: 'All categories',
                options: {
                  for (final category in widget.categories)
                    category.id: category.name,
                },
                selected: _categories,
                onChanged: (value) => setState(() => _categories = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type?.name ?? '',
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('All types')),
                  for (final type in TransactionType.values)
                    DropdownMenuItem(
                      value: type.name,
                      child: Text(_typeLabel(type)),
                    ),
                ],
                onChanged: (value) => _type = value == null || value == ''
                    ? null
                    : TransactionType.values.byName(value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minimum,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Minimum amount (₹)',
                ),
                validator: _validateAmount,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maximum,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Maximum amount (₹)',
                ),
                validator: (value) {
                  final error = _validateAmount(value);
                  if (error != null) return error;
                  final min = _parseAmount(_minimum.text);
                  final max = _parseAmount(value ?? '');
                  if (min != null && max != null && min > max) {
                    return 'Maximum must be at least the minimum';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () =>
            Navigator.pop(context, const TransactionSearchFilter()),
        child: const Text('Clear filters'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          Navigator.pop(
            context,
            TransactionSearchFilter(
              from: _dates?.start,
              to: _dates?.end,
              accountIds: _accounts,
              categoryIds: _categories,
              type: _type,
              minAmount: _parseAmount(_minimum.text),
              maxAmount: _parseAmount(_maximum.text),
            ),
          );
        },
        child: const Text('Apply'),
      ),
    ],
  );
}

class _MultiSelectField extends StatelessWidget {
  final String label;
  final String allLabel;
  final Map<String, String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const _MultiSelectField({
    required this.label,
    required this.allLabel,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(
      selected.isEmpty
          ? allLabel
          : selected.map((id) => options[id] ?? id).join(', '),
    ),
    trailing: const Icon(Icons.arrow_drop_down),
    onTap: () async {
      final pending = {...selected};
      final result = await showDialog<Set<String>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(label),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final entry in options.entries)
                      CheckboxListTile(
                        title: Text(entry.value),
                        value: pending.contains(entry.key),
                        onChanged: (checked) => setState(() {
                          if (checked == true) {
                            pending.add(entry.key);
                          } else {
                            pending.remove(entry.key);
                          }
                        }),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, <String>{}),
                child: Text(allLabel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(context, Set<String>.unmodifiable(pending)),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
      if (result != null && context.mounted) onChanged(result);
    },
  );
}

String _money(int amount) =>
    NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(amount / 100);

String _typeLabel(TransactionType type) => switch (type) {
  TransactionType.income => 'Income',
  TransactionType.expense => 'Expense',
  TransactionType.transfer => 'Transfer',
};

String _dateRangeLabel(DateTime? from, DateTime? to) {
  if (from == null && to == null) return 'All history';
  final format = DateFormat.yMMMd();
  return '${from == null ? 'Any date' : format.format(from)} – ${to == null ? 'Any date' : format.format(to)}';
}

String _amountInput(int? amount) =>
    amount == null ? '' : (amount / 100).toStringAsFixed(2);

String? _validateAmount(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return _parseAmount(value) == null
      ? 'Enter a positive amount with up to 2 decimal places'
      : null;
}

int? _parseAmount(String value) {
  final text = value.trim();
  if (!RegExp(r'^\d{1,12}(\.\d{1,2})?$').hasMatch(text)) return null;
  final parts = text.split('.');
  return int.parse(parts[0]) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
}
