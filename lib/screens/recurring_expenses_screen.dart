import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class RecurringExpensesScreen extends StatelessWidget {
  static const routeName = '/recurring-expenses';

  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recurring = Provider.of<AppProvider>(context).recurringExpenses;

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Expenses')),
      body: recurring.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No recurring expenses set up.'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Logic to add recurring expense
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Recurring Bill'),
                  )
                ],
              ),
            )
          : ListView.builder(
              itemCount: recurring.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Text(recurring[i].description),
                subtitle: Text('Every ${recurring[i].interval.name}'),
                trailing: Text('₹${recurring[i].amount}'),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
