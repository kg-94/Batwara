enum GroupType {
  trip,
  home,
  couple,
  movie,
  dining,
  party,
  other,
}

class Group {
  final String id;
  final String name;
  final List<String> memberIds;
  final List<String> expenseIds;
  final String? createdBy;
  final GroupType type;

  Group({
    required this.id,
    required this.name,
    required this.memberIds,
    this.expenseIds = const [],
    this.createdBy,
    this.type = GroupType.other,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'memberIds': memberIds,
      'expenseIds': expenseIds,
      'createdBy': createdBy,
      'type': type.name,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      expenseIds: List<String>.from(map['expenseIds'] ?? []),
      createdBy: map['createdBy'],
      type: GroupType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'other'),
        orElse: () => GroupType.other,
      ),
    );
  }
}
