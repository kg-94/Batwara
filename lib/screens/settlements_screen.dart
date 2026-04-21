import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettlementsScreen extends StatelessWidget {
  static const routeName = '/settlements';

  const SettlementsScreen({super.key});

  Future<void> _launchUPI(BuildContext context, String upiId, String name, double amount) async {
    final Uri uri = Uri.parse(
      'upi://pay?pa=$upiId&pn=$name&am=${amount.toStringAsFixed(2)}&cu=INR',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch UPI app. Please ensure you have a UPI app installed.')),
      );
    }
  }

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
                          final creditor = members.firstWhere((m) => m.id == entry.key);
                          String creditorName = creditor.name;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(creditorName),
                                      if (creditor.upiId != null)
                                        Text(
                                          creditor.upiId!,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${entry.value.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                    ),
                                    if (creditor.upiId != null)
                                      TextButton.icon(
                                        onPressed: () => _launchUPI(
                                          context,
                                          creditor.upiId!,
                                          creditorName,
                                          entry.value,
                                        ),
                                        icon: const Icon(Icons.payment, size: 16),
                                        label: const Text('Pay'),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(50, 30),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                  ],
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
