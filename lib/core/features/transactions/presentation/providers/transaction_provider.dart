
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';


import '../../data/models/transaction_model.dart';
import 'package:budget_pulse/main.dart';

// Selected category filter provider (null means show all)
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Filtered transaction list based on selected category
final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final allTransactions = ref.watch(transactionProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  if (selectedCategory == null || selectedCategory.isEmpty) {
    return allTransactions;
  }

  return allTransactions
      .where((tx) => tx.category.toLowerCase() == selectedCategory.toLowerCase())
      .toList();
});


class TransactionNotifier extends Notifier<List<TransactionModel>>
{

  late final Box<TransactionModel> _box;

  @override
  List<TransactionModel> build() {
    // Watch and retrieve the open Hive box from Riverpod
    _box = ref.watch(transactionBoxProvider);
    // Load initial data synchronously from local database watch query or fetch
    return _fetchTransactionsFromBox();
  }

List<TransactionModel> _fetchTransactionsFromBox() {
    // Get all values from the box and sort them by date descending (newest first)
    final items = _box.values.toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }
// Method to add a new transaction and update UI state automatically
 Future<void> addTransaction({
    required String title,
    required double amount,
    required String category,
    required bool isExpense,
  }) async {
    final newTx = TransactionModel()
      ..transactionId = DateTime.now().millisecondsSinceEpoch.toString()
      ..title = title
      ..amount = amount
      ..date = DateTime.now()
      ..category = category
      ..isExpense = isExpense;

   // Save the object directly into the Hive box
    await _box.add(newTx);

   // Refresh state so UI updates instantly
    state = _fetchTransactionsFromBox();
  }



Future<void> deleteTransaction(TransactionModel transaction) async {
    // HiveObject provides .delete() to remove this exact record from its box
    await transaction.delete();

    // Refresh state to update UI and recalculate balance + chart
    state = _fetchTransactionsFromBox();
  }





Future<String> exportToCsv() async {
    final transactions = state;
    
    // Create CSV Header
    final buffer = StringBuffer();
    buffer.writeln('ID,Title,Amount,Category,Type,Date');

    // Append each transaction row
    for (final tx in transactions) {
      buffer.writeln(
        '"${tx.transactionId}","${tx.title}",${tx.amount},"${tx.category}","${tx.isExpense ? 'Expense' : 'Income'}","${tx.date}"',
      );
    }

    return buffer.toString();
  }

}
  // Global provider exposing our transaction notifier to the UI
final transactionProvider =
    NotifierProvider<TransactionNotifier, List<TransactionModel>>(
  () => TransactionNotifier(),
);
// TransactionNotifier: Manages a reactive list of TransactionItem objects. The build method sets initial mock records so the UI has data out-of-the-box.

// addTransaction: Takes a new transaction item and prepends it to the existing state list, which triggers an instant, jank-free UI rebuild across any widget watching this provider.

// transactionProvider: A global Riverpod provider that gives components across the app direct, compile-safe access to our transaction state without needing a BuildContext.