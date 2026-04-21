import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/expense.dart';
import '../models/group.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppProvider with ChangeNotifier {
  final List<Member> _members = [];
  final List<Expense> _expenses = [];
  final List<Group> _groups = [];
  final _uuid = Uuid();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Member> get members => [..._members];
  List<Expense> get expenses => [..._expenses];
  List<Group> get groups => [..._groups];

  Future<Map<String, dynamic>?> searchUser(String identifier) async {
    // Search by email
    var query = await _db
        .collection('users')
        .where('email', isEqualTo: identifier)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      // Search by phone
      query = await _db
          .collection('users')
          .where('phone', isEqualTo: identifier)
          .limit(1)
          .get();
    }

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      // Don't allow adding yourself
      if (data['uid'] == _auth.currentUser?.uid) return null;
      return data;
    }
    return null;
  }

  void addMemberFromSearch(Map<String, dynamic> userData) {
    if (_members.any((m) => m.id == userData['uid'])) return;

    final newMember = Member(
      id: userData['uid'],
      name: userData['name'],
      upiId: userData['upiId'], // Assumes users might have a upiId in their profile
    );
    _members.add(newMember);
    notifyListeners();
  }

  void addGroup(String name) {
    final newGroup = Group(
      id: _uuid.v4(),
      name: name,
      memberIds: [],
    );
    _groups.add(newGroup);
    notifyListeners();
  }

  void addMember(String name, {String? upiId}) {
    final newMember = Member(
      id: _uuid.v4(),
      name: name,
      upiId: upiId,
    );
    _members.add(newMember);
    notifyListeners();
  }

  void addExpense({
    required String description,
    required double amount,
    required String paidByMemberId,
    required Map<String, double> splitDetails,
    SplitType splitType = SplitType.equal,
    ExpenseCategory category = ExpenseCategory.others,
  }) {
    final newExpense = Expense(
      id: _uuid.v4(),
      description: description,
      amount: amount,
      date: DateTime.now(),
      paidByMemberId: paidByMemberId,
      splitDetails: splitDetails,
      splitType: splitType,
      category: category,
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

  void addFriendToGroup(String groupId, String memberId) {
    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      if (!_groups[groupIndex].memberIds.contains(memberId)) {
        _groups[groupIndex].memberIds.add(memberId);
        notifyListeners();
      }
    }
  }

  void addExpenseToGroup({
    required String groupId,
    required String description,
    required double amount,
    required String paidByMemberId,
    required Map<String, double> splitDetails,
    SplitType splitType = SplitType.equal,
    ExpenseCategory category = ExpenseCategory.others,
  }) {
    final expenseId = _uuid.v4();
    final newExpense = Expense(
      id: expenseId,
      description: description,
      amount: amount,
      date: DateTime.now(),
      paidByMemberId: paidByMemberId,
      splitDetails: splitDetails,
      splitType: splitType,
      category: category,
    );
    _expenses.add(newExpense);

    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      final updatedGroup = Group(
        id: _groups[groupIndex].id,
        name: _groups[groupIndex].name,
        memberIds: _groups[groupIndex].memberIds,
        expenseIds: [..._groups[groupIndex].expenseIds, expenseId],
      );
      _groups[groupIndex] = updatedGroup;
    }
    notifyListeners();
  }

  List<Member> getMembersByGroup(String groupId) {
    final group = _groups.firstWhere((g) => g.id == groupId);
    return _members.where((m) => group.memberIds.contains(m.id)).toList();
  }

  List<Expense> getExpensesByGroup(String groupId) {
    final group = _groups.firstWhere((g) => g.id == groupId);
    return _expenses.where((e) => group.expenseIds.contains(e.id)).toList();
  }

  double getMemberBalanceInGroup(String groupId, String memberId) {
    final groupExpenses = getExpensesByGroup(groupId);
    double balance = 0.0;
    for (var expense in groupExpenses) {
      if (expense.paidByMemberId == memberId) {
        balance += expense.amount;
      }
      if (expense.splitDetails.containsKey(memberId)) {
        balance -= expense.splitDetails[memberId]!;
      }
    }
    return balance;
  }

  Map<String, Map<String, double>> getSettlementsInGroup(String groupId) {
    final groupMembers = getMembersByGroup(groupId);
    Map<String, double> balances = {};
    for (var member in groupMembers) {
      balances[member.id] = getMemberBalanceInGroup(groupId, member.id);
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
