import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class MembersScreen extends StatefulWidget {
  static const routeName = '/members';

  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _foundUser;
  bool _hasSearched = false;

  Future<void> _searchFriend() async {
    final identifier = _searchController.text.trim();
    if (identifier.isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundUser = null;
      _hasSearched = false;
    });

    try {
      final user = await Provider.of<AppProvider>(context, listen: false).searchUser(identifier);
      setState(() {
        _foundUser = user;
        _hasSearched = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error searching for user')),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _addFoundFriend() {
    if (_foundUser != null) {
      Provider.of<AppProvider>(context, listen: false).addMemberFromSearch(_foundUser!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_foundUser!['name']} added to friends!')),
      );
      setState(() {
        _foundUser = null;
        _hasSearched = false;
        _searchController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Manage Friends')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search for friends',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Email or Mobile Number',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onSubmitted: (_) => _searchFriend(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isSearching ? null : _searchFriend,
                      icon: _isSearching 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_hasSearched)
                  _foundUser != null
                      ? Card(
                          elevation: 0,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(_foundUser!['name'][0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(_foundUser!['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(_foundUser!['email'] ?? _foundUser!['phone'] ?? ''),
                            trailing: TextButton.icon(
                              onPressed: _addFoundFriend,
                              icon: const Icon(Icons.add),
                              label: const Text('Add'),
                              style: TextButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        )
                      : const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No user found with those details.', style: TextStyle(color: Colors.grey)),
                          ),
                        ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: appData.members.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Your friend list is empty', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                        const Text('Search for friends above to add them', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: appData.members.length,
                    itemBuilder: (ctx, i) {
                      final member = appData.members[i];
                      final balance = appData.getMemberBalance(member.id);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          child: Text(member.name[0].toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                        ),
                        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: member.upiId != null ? Text(member.upiId!) : null,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              balance >= 0 ? 'Settled' : 'Owes you',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            Text(
                              '₹${balance.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                color: balance >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
