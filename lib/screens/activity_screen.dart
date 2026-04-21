import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/activity_log.dart';
import 'package:intl/intl.dart';

class ActivityScreen extends StatelessWidget {
  static const routeName = '/activity';

  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = Provider.of<AppProvider>(context).activities;

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Feed')),
      body: activities.isEmpty
          ? const Center(child: Text('No activity yet.'))
          : ListView.separated(
              itemCount: activities.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final activity = activities[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getIconColor(activity.type).withOpacity(0.1),
                    child: Icon(_getIcon(activity.type), color: _getIconColor(activity.type), size: 20),
                  ),
                  title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(activity.subtitle),
                  trailing: Text(
                    DateFormat('MMM d, HH:mm').format(activity.timestamp),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              },
            ),
    );
  }

  IconData _getIcon(ActivityType type) {
    switch (type) {
      case ActivityType.expenseAdded: return Icons.add_shopping_cart;
      case ActivityType.expenseUpdated: return Icons.edit;
      case ActivityType.expenseDeleted: return Icons.delete_outline;
      case ActivityType.groupCreated: return Icons.group_add;
      case ActivityType.memberAdded: return Icons.person_add;
      case ActivityType.settlementDone: return Icons.check_circle_outline;
    }
  }

  Color _getIconColor(ActivityType type) {
    switch (type) {
      case ActivityType.expenseAdded: return Colors.orange;
      case ActivityType.settlementDone: return Colors.green;
      case ActivityType.groupCreated: return Colors.blue;
      default: return Colors.grey;
    }
  }
}
