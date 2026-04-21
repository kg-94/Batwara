import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppProvider>(context);
    final expenses = appData.expenses.reversed.toList();

    // Group expenses by category
    Map<ExpenseCategory, double> categoryTotals = {};
    for (var expense in appData.expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    final totalAmount = appData.expenses.fold(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Batwara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Balance Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Spending',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBalanceItem(
                        'I owe',
                        '₹${_calculateTotalOwe(appData).toStringAsFixed(2)}',
                        Colors.white,
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildBalanceItem(
                        'I am owed',
                        '₹${_calculateTotalOwed(appData).toStringAsFixed(2)}',
                        Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (appData.expenses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Insights', style: Theme.of(context).textTheme.titleLarge),
                        TextButton(onPressed: () {}, child: const Text('See Trends')),
                      ],
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Spending by Category',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 180,
                              child: PieChart(
                                PieChartData(
                                  sections: categoryTotals.entries.map((entry) {
                                    final color = _getCategoryColor(entry.key);
                                    return PieChartSectionData(
                                      color: color,
                                      value: entry.value,
                                      title: '',
                                      radius: 20,
                                      badgeWidget: _buildCategoryBadge(entry.key),
                                      badgePositionPercentageOffset: 1.3,
                                    );
                                  }).toList(),
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 40,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: categoryTotals.keys.map((cat) {
                                return _buildLegendItem(cat, _getCategoryColor(cat));
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Expenses', style: Theme.of(context).textTheme.titleLarge),
                      TextButton(onPressed: () {}, child: const Text('View All')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: expenses.length > 5 ? 5 : expenses.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final payer = appData.members.firstWhere((m) => m.id == expenses[i].paidByMemberId);
                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade100),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(expenses[i].category).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getCategoryIcon(expenses[i].category),
                              color: _getCategoryColor(expenses[i].category),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            expenses[i].description,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Paid by ${payer.name}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${expenses[i].amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                DateFormat.yMMMd().format(expenses[i].date),
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLegendItem(ExpenseCategory cat, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(cat.name[0].toUpperCase() + cat.name.substring(1),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCategoryBadge(ExpenseCategory category) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
      ),
      child: Icon(_getCategoryIcon(category), size: 12, color: _getCategoryColor(category)),
    );
  }

  double _calculateTotalOwe(AppProvider appData) {
    // This is a placeholder, actual logic depends on user ID which we'd get from Auth
    return 0.0;
  }

  double _calculateTotalOwed(AppProvider appData) {
    // This is a placeholder
    return 0.0;
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Colors.orange;
      case ExpenseCategory.travel:
        return Colors.blue;
      case ExpenseCategory.rent:
        return Colors.purple;
      case ExpenseCategory.entertainment:
        return Colors.pink;
      case ExpenseCategory.shopping:
        return Colors.green;
      case ExpenseCategory.utilities:
        return Colors.cyan;
      case ExpenseCategory.others:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.travel:
        return Icons.flight;
      case ExpenseCategory.rent:
        return Icons.home;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.utilities:
        return Icons.power;
      case ExpenseCategory.others:
        return Icons.miscellaneous_services;
    }
  }
}
