import 'package:flutter/material.dart';

/// Closed set of supported category icons.
/// Stored as enum name string in DB — fully tree-shakeable.
/// Adding a new icon: add enum value + entry to [categoryIconData] + [categoryIconLabel].
enum CategoryIcon {
  foodDining,
  restaurant,
  groceries,
  coffee,
  transport,
  car,
  train,
  flight,
  shopping,
  clothing,
  bills,
  electricity,
  health,
  medicine,
  entertainment,
  music,
  sports,
  education,
  book,
  personalCare,
  travel,
  hotel,
  home,
  rent,
  salary,
  freelance,
  business,
  investment,
  gift,
  savings,
  insurance,
  other,
}

/// Const mapping from [CategoryIcon] to a tree-shakeable [IconData].
const Map<CategoryIcon, IconData> categoryIconData = {
  CategoryIcon.foodDining: Icons.restaurant,
  CategoryIcon.restaurant: Icons.lunch_dining,
  CategoryIcon.groceries: Icons.shopping_basket,
  CategoryIcon.coffee: Icons.coffee,
  CategoryIcon.transport: Icons.directions_bus,
  CategoryIcon.car: Icons.directions_car,
  CategoryIcon.train: Icons.train,
  CategoryIcon.flight: Icons.flight,
  CategoryIcon.shopping: Icons.shopping_bag,
  CategoryIcon.clothing: Icons.checkroom,
  CategoryIcon.bills: Icons.receipt_long,
  CategoryIcon.electricity: Icons.bolt,
  CategoryIcon.health: Icons.favorite,
  CategoryIcon.medicine: Icons.medication,
  CategoryIcon.entertainment: Icons.movie,
  CategoryIcon.music: Icons.music_note,
  CategoryIcon.sports: Icons.sports_soccer,
  CategoryIcon.education: Icons.school,
  CategoryIcon.book: Icons.menu_book,
  CategoryIcon.personalCare: Icons.spa,
  CategoryIcon.travel: Icons.luggage,
  CategoryIcon.hotel: Icons.hotel,
  CategoryIcon.home: Icons.home,
  CategoryIcon.rent: Icons.house,
  CategoryIcon.salary: Icons.payments,
  CategoryIcon.freelance: Icons.laptop,
  CategoryIcon.business: Icons.business_center,
  CategoryIcon.investment: Icons.trending_up,
  CategoryIcon.gift: Icons.card_giftcard,
  CategoryIcon.savings: Icons.savings,
  CategoryIcon.insurance: Icons.security,
  CategoryIcon.other: Icons.more_horiz,
};

/// Human-readable label for each icon (used in icon picker UI).
const Map<CategoryIcon, String> categoryIconLabel = {
  CategoryIcon.foodDining: 'Food & Dining',
  CategoryIcon.restaurant: 'Restaurant',
  CategoryIcon.groceries: 'Groceries',
  CategoryIcon.coffee: 'Coffee',
  CategoryIcon.transport: 'Transport',
  CategoryIcon.car: 'Car',
  CategoryIcon.train: 'Train',
  CategoryIcon.flight: 'Flight',
  CategoryIcon.shopping: 'Shopping',
  CategoryIcon.clothing: 'Clothing',
  CategoryIcon.bills: 'Bills',
  CategoryIcon.electricity: 'Electricity',
  CategoryIcon.health: 'Health',
  CategoryIcon.medicine: 'Medicine',
  CategoryIcon.entertainment: 'Entertainment',
  CategoryIcon.music: 'Music',
  CategoryIcon.sports: 'Sports',
  CategoryIcon.education: 'Education',
  CategoryIcon.book: 'Book',
  CategoryIcon.personalCare: 'Personal Care',
  CategoryIcon.travel: 'Travel',
  CategoryIcon.hotel: 'Hotel',
  CategoryIcon.home: 'Home',
  CategoryIcon.rent: 'Rent',
  CategoryIcon.salary: 'Salary',
  CategoryIcon.freelance: 'Freelance',
  CategoryIcon.business: 'Business',
  CategoryIcon.investment: 'Investment',
  CategoryIcon.gift: 'Gift',
  CategoryIcon.savings: 'Savings',
  CategoryIcon.insurance: 'Insurance',
  CategoryIcon.other: 'Other',
};

/// Maps legacy int codepoints (Sprint 1) to [CategoryIcon] enum values.
/// Used during v1→v2 migration only.
const Map<int, CategoryIcon> legacyIconCodeMap = {
  0xe533: CategoryIcon.foodDining,
  0xe531: CategoryIcon.transport,
  0xe59c: CategoryIcon.shopping,
  0xe5fb: CategoryIcon.bills,
  0xe3f3: CategoryIcon.health,
  0xe63b: CategoryIcon.entertainment,
  0xe80c: CategoryIcon.education,
  0xe7fd: CategoryIcon.personalCare,
  0xe1d5: CategoryIcon.travel,
  0xe8b8: CategoryIcon.other,
  0xe263: CategoryIcon.salary,
  0xe8d5: CategoryIcon.freelance,
  0xe1d3: CategoryIcon.business,
  0xe8dc: CategoryIcon.investment,
  0xe40c: CategoryIcon.gift,
};

/// Returns the [IconData] for [icon], falling back to [Icons.label_outline].
IconData resolveIcon(CategoryIcon? icon) => icon != null
    ? categoryIconData[icon] ?? Icons.label_outline
    : Icons.label_outline;

/// Parses a DB string to [CategoryIcon], returns null on unknown values.
CategoryIcon? parseCategoryIcon(String? value) {
  if (value == null) return null;
  try {
    return CategoryIcon.values.byName(value);
  } catch (_) {
    return null;
  }
}
