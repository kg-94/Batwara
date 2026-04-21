import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import './add_expense_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  static const routeName = '/group-detail';

  const GroupDetailScreen({super.key});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final _memberNameController = TextEditingController();

  void _showAddMemberDialog(String groupId) {
    final appData = Provider.of<AppProvider>(context, listen: false);
    final friendsNotInGroup = appData.members
        .where((m) => !appData.groups.firstWhere((g) => g.id == groupId).memberIds.contains(m.id))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Friend to Group'),
        content: friendsNotInGroup.isEmpty
            ? const Text('All your friends are already in this group or you have no friends added.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: friendsNotInGroup.length,
                  itemBuilder: (ctx, i) => ListTile(
                    leading: CircleAvatar(child: Text(friendsNotInGroup[i].name[0])),
                    title: Text(friendsNotInGroup[i].name),
                    onTap: () {
                      appData.addFriendToGroup(groupId, friendsNotInGroup[i].id);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupId = ModalRoute.of(context)!.settings.arguments as String;
    final appData = Provider.of<AppProvider>(context);
    final group = appData.groups.firstWhere((g) => g.id == groupId);
    final groupMembers = appData.getMembersByGroup(groupId);
    final groupExpenses = appData.getExpensesByGroup(groupId);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Balances'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => _showAddMemberDialog(groupId),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Expenses Tab
            groupExpenses.isEmpty
                ? const Center(child: Text('No expenses yet.'))
                : ListView.builder(
                    itemCount: groupExpenses.length,
                    itemBuilder: (ctx, i) => ListTile(
                      title: Text(groupExpenses[i].description),
                      subtitle: Text(
                          'Paid by ${appData.members.firstWhere((m) => m.id == groupExpenses[i].paidByMemberId).name}'),
                      trailing: Text('₹${groupExpenses[i].amount.toStringAsFixed(2)}'),
                    ),
                  ),
            // Balances Tab
            groupMembers.isEmpty
                ? const Center(child: Text('No members in this group.'))
                : ListView.builder(
                    itemCount: groupMembers.length,
                    itemBuilder: (ctx, i) {
                      final balance = appData.getMemberBalanceInGroup(groupId, groupMembers[i].id);
                      return ListTile(
                        leading: CircleAvatar(child: Text(groupMembers[i].name[0])),
                        title: Text(groupMembers[i].name),
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
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
             if (groupMembers.length < 2) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please add at least 2 members to the group first!')),
              );
            } else {
              // We need to update AddExpenseScreen to support GroupId or pass it via arguments
              Navigator.of(context).pushNamed(AddExpenseScreen.routeName, arguments: groupId);
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
