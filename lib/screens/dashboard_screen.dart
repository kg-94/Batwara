import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import './add_expense_screen.dart';
import './members_screen.dart';
import './settlements_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppProvider>(context);
    final expenses = appData.expenses.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batwara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => Navigator.of(context).pushNamed(MembersScreen.routeName),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(15),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Expenses', style: TextStyle(fontSize: 20)),
                  Text(
                    '₹${appData.expenses.fold(0.0, (sum, item) => sum + item.amount).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (ctx, i) {
                final payer = appData.members.firstWhere((m) => m.id == expenses[i].paidByMemberId);
                return ListTile(
                  title: Text(expenses[i].description),
                  subtitle: Text('Paid by ${payer.name} on ${DateFormat.yMMMd().format(expenses[i].date)}'),
                  trailing: Text('₹${expenses[i].amount.toStringAsFixed(2)}'),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(SettlementsScreen.routeName),
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Settlements'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (appData.members.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please add at least 2 members first!')),
                  );
                  Navigator.of(context).pushNamed(MembersScreen.routeName);
                } else {
                  Navigator.of(context).pushNamed(AddExpenseScreen.routeName);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
