import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/models/transaction_model.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/models/category_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            hintText: 'Поиск транзакций...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black38),
          ),
        ),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          final filtered = transactions.where((t) {
            final category = t.category.toLowerCase();
            final desc = (t.description ?? '').toLowerCase();
            final amount = t.amount.toString();
            return category.contains(_query) ||
                desc.contains(_query) ||
                amount.contains(_query);
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    _query.isEmpty ? "Введите запрос" : "Ничего не найдено",
                    style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final transaction = filtered[index];
              final isExpense = transaction.type == TransactionType.expense;
              final category = CategoriesData.getCategoryByName(
                transaction.category,
                isExpense,
              );

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (category?.color ?? Colors.grey).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category?.icon ?? Icons.help_outline,
                      color: category?.color ?? Colors.grey,
                    ),
                  ),
                  title: Text(
                    transaction.category,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    transaction.description?.isNotEmpty == true
                        ? transaction.description!
                        : DateFormat('dd MMM yyyy', 'ru').format(transaction.date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${isExpense ? '-' : '+'}${CurrencyUtils.formatTengeShort(transaction.amount)}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isExpense ? Colors.red.shade400 : Colors.green.shade400,
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка: $err')),
      ),
    );
  }
}