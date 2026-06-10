import 'package:equatable/equatable.dart';

import '../../../core/database/app_database.dart';
import 'category_icon.dart';

final class Category extends Equatable {
  final String id;
  final String name;
  final String? parentId;
  final CategoryType type;

  /// Tree-shakeable enum icon. Preferred over [iconCode].
  final CategoryIcon? iconEnum;

  /// Legacy int codepoint — retained for data compatibility; prefer [iconEnum].
  final int? iconCode;

  final String? colorHex;
  final bool isSystem;
  final int sortOrder;
  final List<Category> children;

  const Category({
    required this.id,
    required this.name,
    this.parentId,
    required this.type,
    this.iconEnum,
    this.iconCode,
    this.colorHex,
    required this.isSystem,
    required this.sortOrder,
    this.children = const [],
  });

  factory Category.fromData(CategoryData data) {
    return Category(
      id: data.id,
      name: data.name,
      parentId: data.parentId,
      type: data.type,
      iconEnum: parseCategoryIcon(data.icon),
      iconCode: data.iconCode,
      colorHex: data.colorHex,
      isSystem: data.isSystem,
      sortOrder: data.sortOrder,
    );
  }

  bool get isRoot => parentId == null;

  @override
  List<Object?> get props => [
    id,
    name,
    parentId,
    type,
    iconEnum,
    iconCode,
    colorHex,
    isSystem,
    sortOrder,
  ];
}

/// Builds a tree from a flat list of categories.
List<Category> buildCategoryTree(List<Category> flat) {
  final map = <String, Category>{};
  final roots = <Category>[];
  final childrenMap = <String, List<Category>>{};

  for (final cat in flat) {
    map[cat.id] = cat;
  }
  for (final cat in flat) {
    if (cat.parentId == null) {
      roots.add(cat);
    } else {
      childrenMap.putIfAbsent(cat.parentId!, () => []).add(cat);
    }
  }

  Category attachChildren(Category cat) {
    final kids = childrenMap[cat.id] ?? [];
    return Category(
      id: cat.id,
      name: cat.name,
      parentId: cat.parentId,
      type: cat.type,
      iconEnum: cat.iconEnum,
      iconCode: cat.iconCode,
      colorHex: cat.colorHex,
      isSystem: cat.isSystem,
      sortOrder: cat.sortOrder,
      children: kids.map(attachChildren).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }

  return roots.map(attachChildren).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}
