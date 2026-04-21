import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/expense.dart';
import '../models/group.dart';
import '../models/activity_log.dart';
import '../models/recurring_expense.dart';
import '../models/settlement.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Group;

class AppProvider with ChangeNotifier {
  final List<Member> _members = [];
  final List<Expense> _expenses = [];
  final List<Group> _groups = [];
  final List<ActivityLog> _activities = [];
  final List<RecurringExpense> _recurringExpenses = [];
  final List<Settlement> _settlementHistory = [];
  final List<Map<String, dynamic>> _recommendedFriends = [];
  final _uuid = Uuid();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Member> get members => [..._members];
  List<Expense> get expenses => [..._expenses];
  List<Group> get groups => [..._groups];
  List<ActivityLog> get activities => [..._activities];
  List<RecurringExpense> get recurringExpenses => [..._recurringExpenses];
  List<Settlement> get settlementHistory => [..._settlementHistory];
  List<Map<String, dynamic>> get recommendedFriends => [..._recommendedFriends];

  void _logActivity(String title, String subtitle, ActivityType type, {String? groupId}) {
    final activity = ActivityLog(
      id: _uuid.v4(),
      title: title,
      subtitle: subtitle,
      timestamp: DateTime.now(),
      type: type,
      groupId: groupId,
      userId: _auth.currentUser?.uid ?? 'unknown',
    );
    _activities.insert(0, activity);
    notifyListeners();
  }

  Future<void> syncContacts() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      return;
    }

    final contacts = await FlutterContacts.getContacts(withProperties: true);
    final List<String> phoneNumbers = [];

    for (var contact in contacts) {
      for (var phone in contact.phones) {
        String normalized = phone.number.replaceAll(RegExp(r'\D'), '');
        if (normalized.length >= 10) {
          normalized = normalized.substring(normalized.length - 10);
          phoneNumbers.add(normalized);
        }
      }
    }

    if (phoneNumbers.isEmpty) return;
    _recommendedFriends.clear();

    for (var i = 0; i < phoneNumbers.length; i += 30) {
      int end = (i + 30 < phoneNumbers.length) ? i + 30 : phoneNumbers.length;
      final batch = phoneNumbers.sublist(i, end);

      final query = await _db
          .collection('users')
          .where('phone', whereIn: batch)
          .get();

      for (var doc in query.docs) {
        final data = doc.data();
        if (data['uid'] != _auth.currentUser?.uid &&
            !_members.any((m) => m.id == data['uid']) &&
            !_recommendedFriends.any((rf) => rf['uid'] == data['uid'])) {
          _recommendedFriends.add(data);
        }
      }
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> searchUser(String identifier) async {
    var query = await _db.collection('users').where('email', isEqualTo: identifier).limit(1).get();
    if (query.docs.isEmpty) {
      query = await _db.collection('users').where('phone', isEqualTo: identifier).limit(1).get();
    }
    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      if (data['uid'] == _auth.currentUser?.uid) return null;
      return data;
    }
    return null;
  }

  void addMemberFromSearch(Map<String, dynamic> userData) {
    if (_members.any((m) => m.id == userData['uid'])) return;
    final newMember = Member(id: userData['uid'], name: userData['name'], upiId: userData['upiId']);
    _members.add(newMember);
    _logActivity('Added Friend', '${userData['name']} is now your friend', ActivityType.memberAdded);
    notifyListeners();
  }

  void addGroup(String name) {
    final groupId = _uuid.v4();
    final newGroup = Group(id: groupId, name: name, memberIds: []);
    _groups.add(newGroup);
    _logActivity('Group Created', 'You created group "$name"', ActivityType.groupCreated, groupId: groupId);
    notifyListeners();
  }

  void addMember(String name, {String? upiId}) {
    final newMember = Member(id: _uuid.v4(), name: name, upiId: upiId);
    _members.add(newMember);
    _logActivity('Added Friend', 'Added $name manually', ActivityType.memberAdded);
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
    _logActivity('Expense Added', 'Added "$description" for ₹$amount', ActivityType.expenseAdded);
    notifyListeners();
  }

  void settleDebt(String fromId, String toId, double amount, {String? groupId}) {
    final settlement = Settlement(
      id: _uuid.v4(),
      fromMemberId: fromId,
      toMemberId: toId,
      amount: amount,
      date: DateTime.now(),
      groupId: groupId,
    );
    _settlementHistory.insert(0, settlement);
    
    // Create a "settlement" expense to balance things out
    addExpense(
      description: 'Settlement: ${getMemberName(fromId)} to ${getMemberName(toId)}',
      amount: amount,
      paidByMemberId: fromId,
      splitDetails: {toId: amount},
      category: ExpenseCategory.others,
    );

    _logActivity('Settlement Done', '₹$amount paid to ${getMemberName(toId)}', ActivityType.settlementDone, groupId: groupId);
  }

  String getMemberName(String id) {
    if (id == _auth.currentUser?.uid) return 'You';
    final member = _members.firstWhere((m) => m.id == id, orElse: () => Member(id: id, name: 'Unknown'));
    return member.name;
  }

  double getMemberBalance(String memberId) {
    double balance = 0.0;
    for (var expense in _expenses) {
      if (expense.paidByMemberId == memberId) balance += expense.amount;
      if (expense.splitDetails.containsKey(memberId)) balance -= expense.splitDetails[memberId]!;
    }
    return balance;
  }

  void addFriendToGroup(String groupId, String memberId) {
    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      if (!_groups[groupIndex].memberIds.contains(memberId)) {
        _groups[groupIndex].memberIds.add(memberId);
        _logActivity('Member Added', '${getMemberName(memberId)} added to group', ActivityType.memberAdded, groupId: groupId);
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
      _logActivity('Expense Added', 'Added "$description" in group', ActivityType.expenseAdded, groupId: groupId);
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
      if (expense.paidByMemberId == memberId) balance += expense.amount;
      if (expense.splitDetails.containsKey(memberId)) balance -= expense.splitDetails[memberId]!;
    }
    return balance;
  }

  Map<String, Map<String, double>> getSettlementsInGroup(String groupId) {
    final groupMembers = getMembersByGroup(groupId);
    Map<String, double> balances = {};
    for (var member in groupMembers) {
      balances[member.id] = getMemberBalanceInGroup(groupId, member.id);
    }
    return _calculateSettlements(balances);
  }

  Map<String, Map<String, double>> getSettlements() {
    Map<String, double> balances = {};
    for (var member in _members) {
      balances[member.id] = getMemberBalance(member.id);
    }
    return _calculateSettlements(balances);
  }

  Map<String, Map<String, double>> _calculateSettlements(Map<String, double> balances) {
    List<String> creditors = balances.keys.where((id) => balances[id]! > 0.01).toList();
    List<String> debtors = balances.keys.where((id) => balances[id]! < -0.01).toList();
    creditors.sort((a, b) => balances[b]!.compareTo(balances[a]!));
    debtors.sort((a, b) => balances[a]!.compareTo(balances[b]!));
    Map<String, Map<String, double>> settlements = {};
    int cIdx = 0; int dIdx = 0;
    while (cIdx < creditors.length && dIdx < debtors.length) {
      String creditor = creditors[cIdx]; String debtor = debtors[dIdx];
      double amountToPay = balances[creditor]! < -balances[debtor]! ? balances[creditor]! : -balances[debtor]!;
      if (amountToPay > 0) {
        if (!settlements.containsKey(debtor)) settlements[debtor] = {};
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
