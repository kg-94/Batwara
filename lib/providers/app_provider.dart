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
import 'dart:async';

class AppProvider with ChangeNotifier {
  List<Member> _members = [];
  List<Expense> _expenses = [];
  List<Group> _groups = [];
  List<ActivityLog> _activities = [];
  List<RecurringExpense> _recurringExpenses = [];
  List<Settlement> _settlementHistory = [];
  final List<Map<String, dynamic>> _recommendedFriends = [];
  final _uuid = Uuid();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription? _groupsSub;
  StreamSubscription? _expensesSub;
  StreamSubscription? _membersSub;

  AppProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _initListeners(user.uid);
      } else {
        _cancelListeners();
      }
    });
  }

  void _initListeners(String uid) {
    _cancelListeners();

    _groupsSub = _db
        .collection('groups')
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .listen((snapshot) {
      _groups = snapshot.docs.map((doc) => Group.fromMap(doc.data())).toList();
      notifyListeners();
    });

    _membersSub = _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .listen((snapshot) {
      _members = snapshot.docs.map((doc) => Member.fromMap(doc.data())).toList();
      _db.collection('users').doc(uid).get().then((doc) {
        if (doc.exists) {
          final data = doc.data();
          final self = Member(id: uid, name: data?['name'] ?? 'You', upiId: data?['upiId'], phone: data?['phone']);
          if (!_members.any((m) => m.id == uid)) {
            _members.add(self);
          }
        }
      });
      notifyListeners();
    });

    _expensesSub = _db
        .collection('expenses')
        .where('splitDetails.$uid', isGreaterThanOrEqualTo: -999999)
        .snapshots()
        .listen((snapshot) {
       _expenses = snapshot.docs.map((doc) => Expense.fromMap(doc.data())).toList();
       notifyListeners();
    });
  }

  void _cancelListeners() {
    _groupsSub?.cancel();
    _expensesSub?.cancel();
    _membersSub?.cancel();
    _groups = [];
    _expenses = [];
    _members = [];
    _activities = [];
  }

  List<Member> get members => [..._members];
  List<Expense> get expenses => [..._expenses];
  List<Group> get groups => [..._groups];
  List<ActivityLog> get activities => [..._activities];
  List<RecurringExpense> get recurringExpenses => [..._recurringExpenses];
  List<Settlement> get settlementHistory => [..._settlementHistory];
  List<Map<String, dynamic>> get recommendedFriends => [..._recommendedFriends];

  Future<void> _logActivity(String title, String subtitle, ActivityType type, {String? groupId}) async {
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
    if (!await FlutterContacts.requestPermission(readonly: true)) return;

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

      final query = await _db.collection('users').where('phone', whereIn: batch).get();

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

  Future<void> addMemberFromSearch(Map<String, dynamic> userData) async {
    if (_members.any((m) => m.id == userData['uid'])) return;
    final newMember = Member(
      id: userData['uid'], 
      name: userData['name'], 
      upiId: userData['upiId'],
      phone: userData['phone'],
    );
    
    await _db
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('friends')
        .doc(newMember.id)
        .set(newMember.toMap());

    _logActivity('Added Friend', '${userData['name']} is now your friend', ActivityType.memberAdded);
  }

  Future<void> addGroup(String name) async {
    final groupId = _uuid.v4();
    final uid = _auth.currentUser!.uid;
    final newGroup = Group(
      id: groupId,
      name: name,
      memberIds: [uid],
      createdBy: uid,
    );
    
    await _db.collection('groups').doc(groupId).set(newGroup.toMap());
    _logActivity('Group Created', 'You created group "$name"', ActivityType.groupCreated, groupId: groupId);
  }

  Future<void> addMember(String name, {String? upiId, String? phone}) async {
    final memberId = _uuid.v4();
    final newMember = Member(id: memberId, name: name, upiId: upiId, phone: phone);
    
    await _db
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('friends')
        .doc(memberId)
        .set(newMember.toMap());

    _logActivity('Added Friend', 'Added $name manually', ActivityType.memberAdded);
  }

  Future<void> addExpense({
    required String description,
    required double amount,
    required String paidByMemberId,
    required Map<String, double> splitDetails,
    SplitType splitType = SplitType.equal,
    ExpenseCategory category = ExpenseCategory.others,
  }) async {
    final id = _uuid.v4();
    final newExpense = Expense(
      id: id,
      description: description,
      amount: amount,
      date: DateTime.now(),
      paidByMemberId: paidByMemberId,
      splitDetails: splitDetails,
      splitType: splitType,
      category: category,
    );
    
    await _db.collection('expenses').doc(id).set(newExpense.toMap());
    _logActivity('Expense Added', 'Added "$description" for ₹$amount', ActivityType.expenseAdded);
  }

  Future<void> settleDebt(String fromId, String toId, double amount, {String? groupId}) async {
    final settlement = Settlement(
      id: _uuid.v4(),
      fromMemberId: fromId,
      toMemberId: toId,
      amount: amount,
      date: DateTime.now(),
      groupId: groupId,
    );
    _settlementHistory.insert(0, settlement);
    
    await addExpense(
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

  Future<void> addFriendToGroup(String groupId, String memberId) async {
    await _db.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([memberId])
    });
    _logActivity('Member Added', '${getMemberName(memberId)} added to group', ActivityType.memberAdded, groupId: groupId);
  }

  Future<void> addExpenseToGroup({
    required String groupId,
    required String description,
    required double amount,
    required String paidByMemberId,
    required Map<String, double> splitDetails,
    SplitType splitType = SplitType.equal,
    ExpenseCategory category = ExpenseCategory.others,
  }) async {
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
    
    WriteBatch batch = _db.batch();
    batch.set(_db.collection('expenses').doc(expenseId), newExpense.toMap());
    batch.update(_db.collection('groups').doc(groupId), {
      'expenseIds': FieldValue.arrayUnion([expenseId])
    });
    
    await batch.commit();
    _logActivity('Expense Added', 'Added "$description" in group', ActivityType.expenseAdded, groupId: groupId);
  }

  List<Member> getMembersByGroup(String groupId) {
    final group = _groups.firstWhere((g) => g.id == groupId, orElse: () => Group(id: '', name: '', memberIds: []));
    if (group.id.isEmpty) return [];
    return _members.where((m) => group.memberIds.contains(m.id)).toList();
  }

  List<Expense> getExpensesByGroup(String groupId) {
    final group = _groups.firstWhere((g) => g.id == groupId, orElse: () => Group(id: '', name: '', memberIds: []));
    if (group.id.isEmpty) return [];
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
