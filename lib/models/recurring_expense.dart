import 'expense.dart';

enum RecurrenceInterval {
  daily,
  weekly,
  monthly,
  yearly,
}

class RecurringExpense {
  final String id;
  final String description;
  final double amount;
  final String paidByMemberId;
  final Map<String, double> splitDetails;
  final SplitType splitType;
  final ExpenseCategory category;
  final RecurrenceInterval interval;
  final DateTime startDate;
  final DateTime? nextDueDate;
  final bool isActive;
  final String? groupId;

  RecurringExpense({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidByMemberId,
    required this.splitDetails,
    this.splitType = SplitType.equal,
    this.category = ExpenseCategory.others,
    required this.interval,
    required this.startDate,
    this.nextDueDate,
    this.isActive = true,
    this.groupId,
  });
}
