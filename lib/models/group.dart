class Group {
  final String id;
  final String name;
  final List<String> memberIds;
  final List<String> expenseIds;
  final String? createdBy;

  Group({
    required this.id,
    required this.name,
    required this.memberIds,
    this.expenseIds = const [],
    this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'memberIds': memberIds,
      'expenseIds': expenseIds,
      'createdBy': createdBy,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      expenseIds: List<String>.from(map['expenseIds'] ?? []),
      createdBy: map['createdBy'],
    );
  }
}
