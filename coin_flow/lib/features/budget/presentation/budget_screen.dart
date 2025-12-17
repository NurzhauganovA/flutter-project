import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/models/transaction_model.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/models/category_model.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Бюджет')),
      body: transactionsAsync.when(
        data: (transactions) {
          // Фильтруем расходы за текущий месяц
          final now = DateTime.now();
          final currentMonthExpenses = transactions.where((t) {
            return t.type == TransactionType.expense &&
                t.date.year == now.year &&
                t.date.month == now.month;
          }).toList();

          if (currentMonthExpenses.isEmpty) {
            return Center(
              child: Text(
                "Нет расходов в этом месяце",
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            );
          }

          // Группируем по категориям
          final Map<String, double> categorySpending = {};
          for (var t in currentMonthExpenses) {
            categorySpending[t.category] = (categorySpending[t.category] ?? 0) + t.amount;
          }

          // Сортируем: от больших трат к меньшим
          final sortedEntries = categorySpending.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final totalSpent = currentMonthExpenses.fold(0.0, (sum, t) => sum + t.amount);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Общая карточка
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF42A5F5), const Color(0xFF1976D2)]
                        : [const Color(0xFF64B5F6), const Color(0xFF2196F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Расходы за месяц",
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyUtils.formatTenge(totalSpent),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                "По категориям",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Список категорий с прогресс-барами
              ...sortedEntries.map((entry) {
                final categoryName = entry.key;
                final amount = entry.value;
                final category = CategoriesData.getCategoryByName(categoryName, true);

                // Процент от общей суммы (для визуализации "веса" категории)
                final percentage = totalSpent > 0 ? (amount / totalSpent) : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (category?.color ?? Colors.grey).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  category?.icon ?? Icons.category,
                                  size: 18,
                                  color: category?.color ?? Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                categoryName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            CurrencyUtils.formatTengeShort(amount),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage, // Заполненность относительно всех трат
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          color: category?.color ?? Colors.teal,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(percentage * 100).toStringAsFixed(1)}% от общих расходов',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }
}