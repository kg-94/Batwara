import 'package:uuid/uuid.dart';

class Expense {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String paidByMemberId;
  final Map<String, double> splitDetails; // memberId -> amount

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.paidByMemberId,
    required this.splitDetails,
  });
}
