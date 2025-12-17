import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/models/transaction_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Widget _buildBudgetList(Map<String, double> categoryTotals) {
    // В реальном приложении лимиты брались бы из настроек
    // Здесь мы симулируем их для демонстрации UI
    final demoLimits = {
      'Food': 500.0,
      'Transport': 200.0,
      'Shopping': 300.0,
      'Entertainment': 150.0,
    };

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: categoryTotals.entries.map((entry) {
            // Показываем бюджет только если категория есть в нашем демо-списке
            if (demoLimits.containsKey(entry.key)) {
              return BudgetProgressItem(
                category: entry.key,
                spent: entry.value,
                limit: demoLimits[entry.key]!,
                color: _getColorForCategory(entry.key),
              );
            }
            return const SizedBox.shrink();
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика расходов')),
      body: transactionsAsync.when(
        data: (transactions) {
          // Фильтруем только расходы
          final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();

          if (expenses.isEmpty) {
            return const Center(child: Text("Нет данных о расходах для аналитики"));
          }

          // Группируем суммы по категориям
          final Map<String, double> categoryTotals = {};
          for (var t in expenses) {
            categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
          }

          final totalExpense = expenses.fold(0.0, (sum, t) => sum + t.amount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // График
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: categoryTotals.entries.map((entry) {
                        final percentage = (entry.value / totalExpense) * 100;
                        return PieChartSectionData(
                          color: _getColorForCategory(entry.key),
                          value: entry.value,
                          title: '${percentage.toStringAsFixed(0)}%',
                          radius: 80,
                          titleStyle: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                Text("Monthly Limits", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Для примера зададим лимиты вручную (в реальном проекте они были бы в БД)
                _buildBudgetList(categoryTotals),

                const SizedBox(height: 40),
                // --- LEGEND ---
                Text("Details", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Легенда (список категорий)
                ...categoryTotals.entries.map((entry) {
                  final percentage = (entry.value / totalExpense) * 100;
                  return Card(
                    elevation: 0,
                    color: Colors.grey.shade50,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getColorForCategory(entry.key),
                        radius: 8,
                      ),
                      title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${percentage.toStringAsFixed(1)}%'),
                      trailing: Text(
                        '\$${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }

  // Генерация цвета для категории
  Color _getColorForCategory(String category) {
    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.pink, Colors.indigo,
    ];
    return colors[category.hashCode % colors.length];
  }
}

// Виджет для одной полоски бюджета
class BudgetProgressItem extends StatelessWidget {
  final String category;
  final double spent;
  final double limit;
  final Color color;

  const BudgetProgressItem({
    super.key,
    required this.category,
    required this.spent,
    required this.limit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (spent / limit).clamp(0.0, 1.0);
    final isExceeded = spent > limit;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '\$${spent.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)}',
                style: TextStyle(
                  color: isExceeded ? Colors.red : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            color: isExceeded ? Colors.red : color,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }
}