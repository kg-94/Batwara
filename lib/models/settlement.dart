class Settlement {
  final String id;
  final String fromMemberId;
  final String toMemberId;
  final double amount;
  final DateTime date;
  final String? groupId;

  Settlement({
    required this.id,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    required this.date,
    this.groupId,
  });
}
