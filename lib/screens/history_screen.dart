import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  static const routeName = '/history';

  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = Provider.of<AppProvider>(context).settlementHistory;

    return Scaffold(
      appBar: AppBar(title: const Text('Settlement History')),
      body: history.isEmpty
          ? const Center(child: Text('No settlements yet.'))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (ctx, i) {
                final s = history[i];
                final appData = Provider.of<AppProvider>(context, listen: false);
                return ListTile(
                  leading: const Icon(Icons.handshake, color: Colors.green),
                  title: Text('${appData.getMemberName(s.fromMemberId)} paid ${appData.getMemberName(s.toMemberId)}'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(s.date)),
                  trailing: Text(
                    '₹${s.amount}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                );
              },
            ),
    );
  }
}
