import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import './group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  static const routeName = '/groups';

  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _groupNameController = TextEditingController();

  void _showAddGroupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Group'),
        content: TextField(
          controller: _groupNameController,
          decoration: const InputDecoration(labelText: 'Group Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_groupNameController.text.isNotEmpty) {
                Provider.of<AppProvider>(context, listen: false)
                    .addGroup(_groupNameController.text.trim());
                _groupNameController.clear();
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = Provider.of<AppProvider>(context).groups;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Groups'),
      ),
      body: groups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_work_outlined, size: 100, color: Colors.grey[200]),
                  const SizedBox(height: 24),
                  Text(
                    'No groups yet.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create one to start splitting expenses\nwith your friends or roommates.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _showAddGroupDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Group'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: groups.length,
              itemBuilder: (ctx, i) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        groups[i].name[0].toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    groups[i].name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.people_outline, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('${groups[i].memberIds.length} members',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      GroupDetailScreen.routeName,
                      arguments: groups[i].id,
                    );
                  },
                ),
              ),
            ),
      floatingActionButton: groups.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddGroupDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
