import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  static const routeName = '/add-expense';

  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedPayerId;
  final Map<String, bool> _selectedMembers = {};

  @override
  void initState() {
    super.initState();
    final appData = Provider.of<AppProvider>(context, listen: false);
    if (appData.members.isNotEmpty) {
      _selectedPayerId = appData.members[0].id;
      for (var member in appData.members) {
        _selectedMembers[member.id] = true;
      }
    }
  }

  void _saveExpense() {
    final description = _descriptionController.text;
    final amount = double.tryParse(_amountController.text) ?? 0;
    
    final splitWith = _selectedMembers.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (description.isEmpty || amount <= 0 || _selectedPayerId == null || splitWith.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select members to split with.')),
      );
      return;
    }

    final splitAmount = amount / splitWith.length;
    final Map<String, double> splitDetails = {
      for (var id in splitWith) id: splitAmount
    };

    Provider.of<AppProvider>(context, listen: false).addExpense(
      description: description,
      amount: amount,
      paidByMemberId: _selectedPayerId!,
      splitDetails: splitDetails,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppProvider>(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            const Text('Paid By:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedPayerId,
              items: appData.members.map((member) {
                return DropdownMenuItem(
                  value: member.id,
                  child: Text(member.name),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedPayerId = val;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text('Split Between:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...appData.members.map((member) {
              return CheckboxListTile(
                title: Text(member.name),
                value: _selectedMembers[member.id] ?? false,
                onChanged: (val) {
                  setState(() {
                    _selectedMembers[member.id] = val ?? false;
                  });
                },
              );
            }).toList(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
