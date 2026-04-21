import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class MembersScreen extends StatefulWidget {
  static const routeName = '/members';

  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _nameController = TextEditingController();

  void _submitData() {
    final enteredName = _nameController.text;
    if (enteredName.isEmpty) return;

    Provider.of<AppProvider>(context, listen: false).addMember(enteredName);
    _nameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Members')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Member Name'),
                    onSubmitted: (_) => _submitData(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, size: 40, color: Colors.teal),
                  onPressed: _submitData,
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: appData.members.length,
              itemBuilder: (ctx, i) {
                final balance = appData.getMemberBalance(appData.members[i].id);
                return ListTile(
                  leading: CircleAvatar(child: Text(appData.members[i].name[0])),
                  title: Text(appData.members[i].name),
                  trailing: Text(
                    '₹${balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: balance >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
