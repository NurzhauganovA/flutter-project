import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isExpense;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isExpense = true,
  });
}

class CategoriesData {
  // Категории расходов
  static const List<CategoryModel> expenseCategories = [
    CategoryModel(
      id: 'food',
      name: 'Еда',
      icon: Icons.restaurant,
      color: Color(0xFFFF6B6B),
    ),
    CategoryModel(
      id: 'transport',
      name: 'Транспорт',
      icon: Icons.directions_car,
      color: Color(0xFF4ECDC4),
    ),
    CategoryModel(
      id: 'shopping',
      name: 'Покупки',
      icon: Icons.shopping_bag,
      color: Color(0xFFFFBE0B),
    ),
    CategoryModel(
      id: 'entertainment',
      name: 'Развлечения',
      icon: Icons.movie,
      color: Color(0xFFAB47BC),
    ),
    CategoryModel(
      id: 'health',
      name: 'Здоровье',
      icon: Icons.medical_services,
      color: Color(0xFF26A69A),
    ),
    CategoryModel(
      id: 'education',
      name: 'Образование',
      icon: Icons.school,
      color: Color(0xFF5C6BC0),
    ),
    CategoryModel(
      id: 'bills',
      name: 'Счета',
      icon: Icons.receipt_long,
      color: Color(0xFFEF5350),
    ),
    CategoryModel(
      id: 'travel',
      name: 'Путешествия',
      icon: Icons.flight,
      color: Color(0xFF29B6F6),
    ),
    CategoryModel(
      id: 'gym',
      name: 'Спорт',
      icon: Icons.fitness_center,
      color: Color(0xFFFF7043),
    ),
    CategoryModel(
      id: 'pets',
      name: 'Питомцы',
      icon: Icons.pets,
      color: Color(0xFF8D6E63),
    ),
    CategoryModel(
      id: 'gifts',
      name: 'Подарки',
      icon: Icons.card_giftcard,
      color: Color(0xFFEC407A),
    ),
    CategoryModel(
      id: 'other',
      name: 'Другое',
      icon: Icons.more_horiz,
      color: Color(0xFF78909C),
    ),
  ];

  // Категории доходов
  static const List<CategoryModel> incomeCategories = [
    CategoryModel(
      id: 'salary',
      name: 'Зарплата',
      icon: Icons.attach_money,
      color: Color(0xFF66BB6A),
      isExpense: false,
    ),
    CategoryModel(
      id: 'freelance',
      name: 'Фриланс',
      icon: Icons.laptop_mac,
      color: Color(0xFF26A69A),
      isExpense: false,
    ),
    CategoryModel(
      id: 'investment',
      name: 'Инвестиции',
      icon: Icons.trending_up,
      color: Color(0xFF42A5F5),
      isExpense: false,
    ),
    CategoryModel(
      id: 'bonus',
      name: 'Бонус',
      icon: Icons.star,
      color: Color(0xFFFFCA28),
      isExpense: false,
    ),
    CategoryModel(
      id: 'gift',
      name: 'Подарок',
      icon: Icons.redeem,
      color: Color(0xFFAB47BC),
      isExpense: false,
    ),
    CategoryModel(
      id: 'other_income',
      name: 'Другое',
      icon: Icons.account_balance_wallet,
      color: Color(0xFF78909C),
      isExpense: false,
    ),
  ];

  // Получить категорию по ID
  static CategoryModel? getCategoryById(String id, bool isExpense) {
    final categories = isExpense ? expenseCategories : incomeCategories;
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Получить категорию по имени
  static CategoryModel? getCategoryByName(String name, bool isExpense) {
    final categories = isExpense ? expenseCategories : incomeCategories;
    try {
      return categories.firstWhere((c) => c.name == name);
    } catch (e) {
      return null;
    }
  }

  // Получить цвет категории
  static Color getCategoryColor(String name) {
    final expense = getCategoryByName(name, true);
    if (expense != null) return expense.color;

    final income = getCategoryByName(name, false);
    if (income != null) return income.color;

    return const Color(0xFF78909C);
  }

  // Получить иконку категории
  static IconData getCategoryIcon(String name) {
    final expense = getCategoryByName(name, true);
    if (expense != null) return expense.icon;

    final income = getCategoryByName(name, false);
    if (income != null) return income.icon;

    return Icons.more_horiz;
  }
}