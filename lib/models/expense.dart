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
  final Map<String, double> splitDetails; // memberId -> amount or percentage or shares

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
}
