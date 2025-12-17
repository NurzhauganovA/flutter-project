import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart'; // Не забудьте: flutter pub add collection
import '../../auth/presentation/auth_controller.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/models/transaction_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Wallet', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: transactionsAsync.when(
          data: (transactions) {
            // Считаем суммы
            final income = transactions
                .where((t) => t.type == TransactionType.income)
                .fold(0.0, (sum, t) => sum + t.amount);
            final expense = transactions
                .where((t) => t.type == TransactionType.expense)
                .fold(0.0, (sum, t) => sum + t.amount);
            final totalBalance = income - expense;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Карточка Баланса
                        _buildBalanceCard(totalBalance, income, expense),
                        const SizedBox(height: 24),

                        // Заголовок и кнопка
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Recent Transactions",
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
                            IconButton(
                              icon: const Icon(Icons.add_circle, size: 40, color: Colors.teal),
                              onPressed: () => context.push('/add-transaction'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Список транзакций
                _buildGroupedTransactionList(transactions, context, ref),

                // Отступ снизу
                const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double total, double income, double expense) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade800, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total Balance", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFinanceStat("Income", income, Icons.arrow_upward, Colors.greenAccent),
              _buildFinanceStat("Expense", expense, Icons.arrow_downward, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceStat(String label, double amount, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
            Text(
              '\$${amount.toStringAsFixed(0)}',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGroupedTransactionList(List<TransactionModel> transactions, BuildContext context, WidgetRef ref) {
    if (transactions.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text("No transactions yet")),
        ),
      );
    }

    // Группировка
    final grouped = groupBy(transactions, (TransactionModel t) {
      return DateTime(t.date.year, t.date.month, t.date.day);
    });

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final date = sortedDates[index];
          final dayTransactions = grouped[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _formatDateHeader(date),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
              ...dayTransactions.map((t) => _buildTransactionItem(t, context, ref)).toList(),
            ],
          );
        },
        childCount: sortedDates.length,
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return "TODAY";
    if (date == yesterday) return "YESTERDAY";
    return DateFormat.yMMMd().format(date).toUpperCase();
  }

  Widget _buildTransactionItem(TransactionModel transaction, BuildContext context, WidgetRef ref) {
    final isExpense = transaction.type == TransactionType.expense;
    final color = isExpense ? Colors.redAccent : const Color(0xFF00BFA5);
    final sign = isExpense ? "-" : "+";

    return Dismissible(
      key: Key(transaction.id ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.red.shade900),
      ),
      onDismissed: (_) => ref.read(transactionsRepositoryProvider).deleteTransaction(transaction.id!),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isExpense ? Icons.shopping_cart_outlined : Icons.account_balance_wallet_outlined,
              color: color,
            ),
          ),
          title: Text(
            transaction.category,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: transaction.description != null && transaction.description!.isNotEmpty
              ? Text(transaction.description!, style: const TextStyle(fontSize: 12))
              : null,
          trailing: Text(
            '$sign\$${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}