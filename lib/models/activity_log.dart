enum ActivityType {
  expenseAdded,
  expenseUpdated,
  expenseDeleted,
  groupCreated,
  memberAdded,
  settlementDone,
}

class ActivityLog {
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final ActivityType type;
  final String? groupId;
  final String userId;

  ActivityLog({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
    this.groupId,
    required this.userId,
  });
}
