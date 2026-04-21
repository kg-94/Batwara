class Member {
  final String id;
  final String name;
  final String? upiId;
  final String? phone;

  Member({
    required this.id,
    required this.name,
    this.upiId,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'upiId': upiId,
      'phone': phone,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      upiId: map['upiId'],
      phone: map['phone'],
    );
  }
}
