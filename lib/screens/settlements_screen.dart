import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class SettlementsScreen extends StatelessWidget {
  static const routeName = '/settlements';

  const SettlementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppProvider>(context);
    final settlements = appData.getSettlements();
    final members = appData.members;

    return Scaffold(
      appBar: AppBar(title: const Text('Settlements')),
      body: settlements.isEmpty
          ? const Center(child: Text('All settled up!'))
          : ListView.builder(
              itemCount: settlements.length,
              itemBuilder: (ctx, i) {
                String debtorId = settlements.keys.elementAt(i);
                String debtorName = members.firstWhere((m) => m.id == debtorId).name;
                Map<String, double> payments = settlements[debtorId]!;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$debtorName owes:',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Divider(),
                        ...payments.entries.map((entry) {
                          String creditorName = members.firstWhere((m) => m.id == entry.key).name;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(creditorName),
                                Text(
                                  '₹${entry.value.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
