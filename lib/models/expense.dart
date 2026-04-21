enum SplitType {
  equal,
  percentage,
  shares,
  exact,
}

enum ExpenseCategory {
  food,
  travel,
  rent,
  entertainment,
  shopping,
  utilities,
  others,
}

class Expense {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String paidByMemberId;
  final SplitType splitType;
  final ExpenseCategory category;
  final Map<String, double> splitDetails;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.paidByMemberId,
    required this.splitDetails,
    this.splitType = SplitType.equal,
    this.category = ExpenseCategory.others,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'paidByMemberId': paidByMemberId,
      'splitType': splitType.index,
      'category': category.index,
      'splitDetails': splitDetails,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      paidByMemberId: map['paidByMemberId'] ?? '',
      splitType: SplitType.values[map['splitType'] ?? 0],
      category: ExpenseCategory.values[map['category'] ?? 6],
      splitDetails: Map<String, double>.from(map['splitDetails'] ?? {}),
    );
  }
}
