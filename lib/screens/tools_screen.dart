import 'package:flutter/material.dart';

class ToolsScreen extends StatefulWidget {
  static const routeName = '/tools';

  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final _amountController = TextEditingController();
  final _peopleController = TextEditingController();
  double? _result;

  void _calculate() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final people = int.tryParse(_peopleController.text) ?? 1;
    if (people > 0) {
      setState(() {
        _result = amount / people;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Tools')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Split Calculator',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _peopleController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of People',
                prefixIcon: Icon(Icons.people),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 32),
            if (_result != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.shade100),
                ),
                child: Column(
                  children: [
                    const Text('Each Person Pays', style: TextStyle(color: Colors.teal)),
                    const SizedBox(height: 8),
                    Text(
                      '₹${_result!.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
