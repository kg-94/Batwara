import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/expense.dart';
import 'package:uuid/uuid.dart';

class AppProvider with ChangeNotifier {
  final List<Member> _members = [];
  final List<Expense> _expenses = [];
  final _uuid = Uuid();

  List<Member> get members => [..._members];
  List<Expense> get expenses => [..._expenses];

  void addMember(String name) {
    final newMember = Member(
      id: _uuid.v4(),
      name: name,
    );
    _members.add(newMember);
    notifyListeners();
  }

  void addExpense({
    required String description,
    required double amount,
    required String paidByMemberId,
    required Map<String, double> splitDetails,
  }) {
    final newExpense = Expense(
      id: _uuid.v4(),
      description: description,
      amount: amount,
      date: DateTime.now(),
      paidByMemberId: paidByMemberId,
      splitDetails: splitDetails,
    );
    _expenses.add(newExpense);
    notifyListeners();
  }

  double getMemberBalance(String memberId) {
    double balance = 0.0;
    for (var expense in _expenses) {
      if (expense.paidByMemberId == memberId) {
        balance += expense.amount;
      }
      if (expense.splitDetails.containsKey(memberId)) {
        balance -= expense.splitDetails[memberId]!;
      }
    }
    return balance;
  }
  
  Map<String, Map<String, double>> getSettlements() {
    Map<String, double> balances = {};
    for (var member in _members) {
      balances[member.id] = getMemberBalance(member.id);
    }

    List<String> creditors = balances.keys.where((id) => balances[id]! > 0.01).toList();
    List<String> debtors = balances.keys.where((id) => balances[id]! < -0.01).toList();

    creditors.sort((a, b) => balances[b]!.compareTo(balances[a]!));
    debtors.sort((a, b) => balances[a]!.compareTo(balances[b]!));

    Map<String, Map<String, double>> settlements = {};

    int cIdx = 0;
    int dIdx = 0;

    while (cIdx < creditors.length && dIdx < debtors.length) {
      String creditor = creditors[cIdx];
      String debtor = debtors[dIdx];
      
      double amountToPay = balances[creditor]! < -balances[debtor]! 
          ? balances[creditor]! 
          : -balances[debtor]!;

      if (amountToPay > 0) {
        if (!settlements.containsKey(debtor)) {
          settlements[debtor] = {};
        }
        settlements[debtor]![creditor] = amountToPay;
        
        balances[creditor] = balances[creditor]! - amountToPay;
        balances[debtor] = balances[debtor]! + amountToPay;
      }

      if (balances[creditor]! < 0.01) cIdx++;
      if (balances[debtor]! > -0.01) dIdx++;
    }

    return settlements;
  }
}
