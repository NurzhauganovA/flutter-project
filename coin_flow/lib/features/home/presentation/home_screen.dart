import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/models/transaction_model.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/models/category_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
                // Кастомный AppBar
                SliverAppBar(
                  expandedHeight: 80,
                  floating: true,
                  pinned: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    title: Text(
                      'Мой кошелек',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.search,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onPressed: () => context.push('/search'),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onPressed: () => context.push('/settings'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Улучшенная карточка баланса
                        _buildBalanceCard(totalBalance, income, expense, isDark),
                        const SizedBox(height: 32),

                        // Быстрые действия
                        _buildQuickActions(context, isDark),
                        const SizedBox(height: 32),

                        // Заголовок транзакций
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Последние транзакции",
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Показать все транзакции
                              },
                              child: Text(
                                'Все',
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Список транзакций
                _buildGroupedTransactionList(transactions, context, ref, isDark),

                // Отступ снизу
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Ошибка: $err')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-transaction'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
        elevation: 4,
      ),
    );
  }

  Widget _buildBalanceCard(double total, double income, double expense, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF00E5FF), const Color(0xFF00BFA5)]
              : [const Color(0xFF00BFA5), const Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF00BFA5))
                .withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Общий баланс",
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      total >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      total >= 0 ? 'Хорошо' : 'В минусе',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyUtils.formatTenge(total),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _buildFinanceStat(
                  "Доход",
                  income,
                  Icons.arrow_upward_rounded,
                  const Color(0xFF66BB6A),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFinanceStat(
                  "Расход",
                  expense,
                  Icons.arrow_downward_rounded,
                  const Color(0xFFEF5350),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceStat(String label, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyUtils.formatTengeShort(amount),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            'Расход',
            Icons.remove_circle_outline,
            const Color(0xFFEF5350),
            isDark,
                () => context.push('/add-transaction', extra: {'type': 'expense'}),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            'Доход',
            Icons.add_circle_outline,
            const Color(0xFF66BB6A),
            isDark,
                () => context.push('/add-transaction', extra: {'type': 'income'}),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            'Бюджет',
            Icons.account_balance_wallet_outlined,
            const Color(0xFF42A5F5),
            isDark,
                () => context.push('/budgets'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      String label,
      IconData icon,
      Color color,
      bool isDark,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark
              ? color.withOpacity(0.15)
              : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedTransactionList(
      List<TransactionModel> transactions,
      BuildContext context,
      WidgetRef ref,
      bool isDark,
      ) {
    if (transactions.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                "Нет транзакций",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Добавьте свою первую транзакцию",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Показываем только последние 10 транзакций на главном экране
    final recentTransactions = transactions.take(10).toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) => _buildTransactionItem(
            recentTransactions[index],
            context,
            ref,
            isDark,
          ),
          childCount: recentTransactions.length,
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
      TransactionModel transaction,
      BuildContext context,
      WidgetRef ref,
      bool isDark,
      ) {
    final isExpense = transaction.type == TransactionType.expense;
    final category = CategoriesData.getCategoryByName(
      transaction.category,
      isExpense,
    );

    final color = category?.color ?? const Color(0xFF78909C);
    final icon = category?.icon ?? Icons.more_horiz;
    final sign = isExpense ? "-" : "+";

    return Dismissible(
      key: Key(transaction.id ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        ref.read(transactionsRepositoryProvider).deleteTransaction(transaction.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Транзакция удалена'),
            action: SnackBarAction(
              label: 'Отменить',
              onPressed: () {
                // TODO: Implement undo
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            transaction.category,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (transaction.description != null && transaction.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    transaction.description!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  DateFormat('dd MMM, HH:mm', 'ru').format(transaction.date),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
          trailing: Text(
            '$sign${CurrencyUtils.formatTengeShort(transaction.amount)}',
            style: GoogleFonts.inter(
              color: isExpense ? Colors.red.shade400 : Colors.green.shade400,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}