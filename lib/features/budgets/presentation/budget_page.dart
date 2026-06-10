import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/extensions/datetime_extensions.dart';
import '../../categories/domain/category.dart';
import '../application/providers.dart';
import '../domain/budget.dart';

/// Monthly budget tracker — set limits per category, see spend vs budget (PBI-002).
class BudgetPage extends ConsumerStatefulWidget {
  const BudgetPage({super.key});

  @override
  ConsumerState<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends ConsumerState<BudgetPage> {
  DateTime _month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(budgetsWithSpendProvider(_month));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budgets'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _MonthSelector(
            current: _month,
            onChanged: (m) => setState(() => _month = m),
          ),
        ),
      ),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (budgets) {
          if (budgets.isEmpty) {
            return _EmptyBudgetState(onAdd: () => _showAddBudgetSheet(context));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: budgets.length,
            itemBuilder: (ctx, i) => _BudgetTile(
              item: budgets[i],
              onEdit: () => _showEditBudgetSheet(context, budgets[i]),
              onDelete: () => ref
                  .read(budgetRepositoryProvider)
                  .delete(budgets[i].budget.id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddBudgetSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BudgetFormSheet(month: _month),
    );
  }

  Future<void> _showEditBudgetSheet(
    BuildContext context,
    BudgetWithSpend item,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BudgetFormSheet(
        month: _month,
        existingBudget: item.budget,
        categoryName: item.categoryName,
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime current;
  final void Function(DateTime) onChanged;

  const _MonthSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChanged(DateTime(current.year, current.month - 1)),
        ),
        Text(
          current.monthYearLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: current.isSameMonth(DateTime.now())
              ? null
              : () => onChanged(DateTime(current.year, current.month + 1)),
        ),
      ],
    );
  }
}

class _EmptyBudgetState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyBudgetState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          const Text('No budgets set for this month'),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Budget'),
          ),
        ],
      ),
    );
  }
}

class _BudgetTile extends StatelessWidget {
  final BudgetWithSpend item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final progressColor = item.isOverBudget
        ? theme.colorScheme.error
        : item.isNearLimit
        ? Colors.orange
        : theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.categoryName,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  '${fmt.format(item.spentMajorUnits)} / ${fmt.format(item.limitMajorUnits)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            if (item.isOverBudget) ...[
              const SizedBox(height: 4),
              Text(
                'Over budget by ${fmt.format((item.spentMajorUnits - item.limitMajorUnits).abs())}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ] else if (item.isNearLimit) ...[
              const SizedBox(height: 4),
              Text(
                '${((1 - item.progress) * 100).toStringAsFixed(0)}% remaining',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetFormSheet extends ConsumerStatefulWidget {
  final DateTime month;
  final Budget? existingBudget;
  final String? categoryName;

  const _BudgetFormSheet({
    required this.month,
    this.existingBudget,
    this.categoryName,
  });

  @override
  ConsumerState<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<_BudgetFormSheet> {
  final _amountController = TextEditingController();
  Category? _selectedCategory;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.existingBudget != null) {
      _amountController.text = (widget.existingBudget!.limitPaise / 100)
          .toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(budgetCategoriesProvider);
    final isEditing = widget.existingBudget != null;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? 'Edit Budget' : 'New Budget',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Category picker (new budget only)
          if (!isEditing)
            categoriesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (cats) => DropdownButtonFormField<Category>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                // ignore: deprecated_member_use
                value: _selectedCategory,
                items: cats
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (c) => setState(() => _selectedCategory = c),
              ),
            )
          else
            Text(widget.categoryName ?? '', style: theme.textTheme.titleMedium),

          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Monthly limit (₹)',
              border: OutlineInputBorder(),
              prefixText: '₹ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Update' : 'Create'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid limit amount');
      return;
    }
    final limitPaise = (amount * 100).round();
    final repo = ref.read(budgetRepositoryProvider);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (widget.existingBudget != null) {
        await repo.update(widget.existingBudget!.id, limitPaise);
      } else {
        if (_selectedCategory == null) {
          setState(() {
            _error = 'Select a category';
            _loading = false;
          });
          return;
        }
        await createBudget(
          repo: repo,
          categoryId: _selectedCategory!.id,
          year: widget.month.year,
          month: widget.month.month,
          limitPaise: limitPaise,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
