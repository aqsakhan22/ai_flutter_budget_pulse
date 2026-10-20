
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';


import '../../data/models/transaction_model.dart';
import 'package:budget_pulse/main.dart';


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

}
  // Global provider exposing our transaction notifier to the UI
final transactionProvider =
    NotifierProvider<TransactionNotifier, List<TransactionModel>>(
  () => TransactionNotifier(),
);
// TransactionNotifier: Manages a reactive list of TransactionItem objects. The build method sets initial mock records so the UI has data out-of-the-box.

// addTransaction: Takes a new transaction item and prepends it to the existing state list, which triggers an instant, jank-free UI rebuild across any widget watching this provider.

// transactionProvider: A global Riverpod provider that gives components across the app direct, compile-safe access to our transaction state without needing a BuildContext.