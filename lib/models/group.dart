class Group {
  final String id;
  final String name;
  final List<String> memberIds;
  final List<String> expenseIds;

  Group({
    required this.id,
    required this.name,
    required this.memberIds,
    this.expenseIds = const [],
  });
}
