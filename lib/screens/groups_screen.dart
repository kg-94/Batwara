import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/group.dart';
import './group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  static const routeName = '/groups';

  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _groupNameController = TextEditingController();
  GroupType _selectedType = GroupType.other;

  void _showAddGroupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Create New Group'),
              IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _groupNameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    hintText: 'e.g. Goa Trip, Apartment 204',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: GroupType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          _selectedType = type;
                        });
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getGroupIcon(type),
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.name[0].toUpperCase() + type.name.substring(1),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (_groupNameController.text.isNotEmpty) {
                  Provider.of<AppProvider>(context, listen: false)
                      .addGroup(_groupNameController.text.trim(), type: _selectedType);
                  _groupNameController.clear();
                  _selectedType = GroupType.other;
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getGroupIcon(GroupType type) {
    switch (type) {
      case GroupType.trip: return Icons.flight_takeoff;
      case GroupType.home: return Icons.home_work;
      case GroupType.couple: return Icons.favorite;
      case GroupType.movie: return Icons.movie;
      case GroupType.dining: return Icons.restaurant;
      case GroupType.party: return Icons.celebration;
      case GroupType.other: return Icons.group_work;
    }
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
                      child: Icon(
                        _getGroupIcon(groups[i].type),
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
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
