import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/expense.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class AddExpenseScreen extends StatefulWidget {
  static const routeName = '/add-expense';

  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedPayerId;
  final Map<String, bool> _selectedMembers = {};
  final Map<String, TextEditingController> _splitControllers = {};
  SplitType _selectedSplitType = SplitType.equal;
  ExpenseCategory _selectedCategory = ExpenseCategory.others;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    final appData = Provider.of<AppProvider>(context, listen: false);
    if (appData.members.isNotEmpty) {
      _selectedPayerId = appData.members[0].id;
      for (var member in appData.members) {
        _selectedMembers[member.id] = true;
        _splitControllers[member.id] = TextEditingController(text: '1');
      }
    }
  }

  Future<void> _scanReceipt() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() => _isScanning = true);

    try {
      final inputImage = InputImage.fromFile(File(image.path));
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String? foundTotal;
      // Simple heuristic: search for "Total" followed by a number or just look for the largest number
      List<double> numbers = [];
      
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final text = line.text.toLowerCase();
          
          // Look for amount-like patterns
          final RegExp amountRegExp = RegExp(r'\d+\.\d{2}');
          final Iterable<RegExpMatch> matches = amountRegExp.allMatches(text);
          
          for (final match in matches) {
            numbers.add(double.parse(match.group(0)!));
          }
          
          if (text.contains('total')) {
             final match = amountRegExp.firstMatch(text);
             if (match != null) {
               foundTotal = match.group(0);
             }
          }
        }
      }

      if (foundTotal != null) {
        _amountController.text = foundTotal;
      } else if (numbers.isNotEmpty) {
        // If "Total" isn't found, pick the largest number (usually the total)
        numbers.sort();
        _amountController.text = numbers.last.toStringAsFixed(2);
      }

      textRecognizer.close();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt scanned successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to scan receipt. Please enter details manually.')),
      );
    } finally {
      setState(() => _isScanning = false);
    }
  }

  @override
  void dispose() {
    for (var controller in _splitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveExpense(String? groupId) {
    final description = _descriptionController.text;
    final amount = double.tryParse(_amountController.text) ?? 0;

    final splitWith = _selectedMembers.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (description.isEmpty || amount <= 0 || _selectedPayerId == null || splitWith.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select members to split with.')),
      );
      return;
    }

    Map<String, double> splitDetails = {};

    if (_selectedSplitType == SplitType.equal) {
      final splitAmount = amount / splitWith.length;
      for (var id in splitWith) {
        splitDetails[id] = splitAmount;
      }
    } else if (_selectedSplitType == SplitType.percentage) {
      double totalPercentage = 0;
      for (var id in splitWith) {
        final val = double.tryParse(_splitControllers[id]!.text) ?? 0;
        totalPercentage += val;
        splitDetails[id] = (val / 100) * amount;
      }
      if ((totalPercentage - 100).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Total percentage must be 100%')),
        );
        return;
      }
    } else if (_selectedSplitType == SplitType.shares) {
      double totalShares = 0;
      for (var id in splitWith) {
        final val = double.tryParse(_splitControllers[id]!.text) ?? 0;
        totalShares += val;
      }
      if (totalShares <= 0) return;
      for (var id in splitWith) {
        final val = double.tryParse(_splitControllers[id]!.text) ?? 0;
        splitDetails[id] = (val / totalShares) * amount;
      }
    } else if (_selectedSplitType == SplitType.exact) {
      double totalExact = 0;
      for (var id in splitWith) {
        final val = double.tryParse(_splitControllers[id]!.text) ?? 0;
        totalExact += val;
        splitDetails[id] = val;
      }
      if ((totalExact - amount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Total of exact amounts must equal the total expense')),
        );
        return;
      }
    }

    if (groupId != null) {
      Provider.of<AppProvider>(context, listen: false).addExpenseToGroup(
        groupId: groupId,
        description: description,
        amount: amount,
        paidByMemberId: _selectedPayerId!,
        splitDetails: splitDetails,
        splitType: _selectedSplitType,
        category: _selectedCategory,
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final groupId = ModalRoute.of(context)?.settings.arguments as String?;
    final appData = Provider.of<AppProvider>(context);
    final members = groupId != null ? appData.getMembersByGroup(groupId) : appData.members;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Add Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _descriptionController,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'What was this for?',
                        prefixIcon: const Icon(Icons.description_outlined),
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                    const Divider(),
                    if (_isScanning)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    else
                      Row(
                        children: [
                          const Icon(Icons.currency_rupee, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                hintText: '0.00',
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: _scanReceipt,
                            icon: const Icon(Icons.camera_alt_outlined),
                            tooltip: 'Scan Receipt',
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: ExpenseCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.name[0].toUpperCase() + cat.name.substring(1)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPayerId,
              decoration: InputDecoration(
                labelText: 'Paid By',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: members.map((member) {
                return DropdownMenuItem(
                  value: member.id,
                  child: Text(member.name),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedPayerId = val),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Split Strategy', style: Theme.of(context).textTheme.titleMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButton<SplitType>(
                    value: _selectedSplitType,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                    items: SplitType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSplitType = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final member = members[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          value: _selectedMembers[member.id] ?? false,
                          activeColor: Theme.of(context).colorScheme.primary,
                          onChanged: (val) => setState(() => _selectedMembers[member.id] = val ?? false),
                        ),
                        if (_selectedMembers[member.id] == true && _selectedSplitType != SplitType.equal)
                          Padding(
                            padding: const EdgeInsets.only(left: 64, right: 16, bottom: 12),
                            child: TextField(
                              controller: _splitControllers[member.id],
                              decoration: InputDecoration(
                                labelText: _selectedSplitType == SplitType.percentage
                                    ? 'Percentage (%)'
                                    : (_selectedSplitType == SplitType.shares ? 'Shares' : 'Amount (₹)'),
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _saveExpense(groupId),
              child: const Text('Create Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
