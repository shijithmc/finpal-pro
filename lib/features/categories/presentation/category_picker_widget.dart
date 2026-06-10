import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../application/providers.dart';
import '../domain/category.dart';
import '../domain/category_icon.dart';

/// Bottom-sheet category picker.
/// Returns the selected [Category] or null (no category).
class CategoryPickerWidget extends ConsumerWidget {
  final CategoryType filterType;
  final String? selectedId;
  final void Function(Category?) onSelected;

  const CategoryPickerWidget({
    super.key,
    required this.filterType,
    this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = filterType == CategoryType.expense
        ? expenseCategoriesProvider
        : incomeCategoriesProvider;
    final categoriesAsync = ref.watch(provider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ListTile(
        title: Text('Error: $e', style: const TextStyle(color: Colors.red)),
      ),
      data: (flat) {
        final tree = buildCategoryTree(flat);
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('No category'),
              selected: selectedId == null,
              onTap: () {
                onSelected(null);
                Navigator.pop(context);
              },
            ),
            ...tree.expand((root) => _buildItems(root, 0, context)),
          ],
        );
      },
    );
  }

  Iterable<Widget> _buildItems(
    Category cat,
    int depth,
    BuildContext context,
  ) sync* {
    yield ListTile(
      contentPadding: EdgeInsets.only(left: 16.0 + depth * 20, right: 16),
      leading: Icon(resolveIcon(cat.iconEnum)),
      title: Text(cat.name),
      selected: selectedId == cat.id,
      onTap: () {
        onSelected(cat);
        Navigator.pop(context);
      },
    );
    for (final child in cat.children) {
      yield* _buildItems(child, depth + 1, context);
    }
  }
}

/// Shows the category picker as a modal bottom sheet.
Future<Category?> showCategoryPicker(
  BuildContext context, {
  required CategoryType type,
  String? selectedId,
}) {
  Category? result;
  return showModalBottomSheet<Category?>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => ListView(
        controller: controller,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(),
          CategoryPickerWidget(
            filterType: type,
            selectedId: selectedId,
            onSelected: (cat) {
              result = cat;
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    ),
  ).then((_) => result);
}
