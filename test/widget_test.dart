import 'dart:io';
import 'package:budget_pulse/core/features/transactions/data/models/transaction_model.dart';
import 'package:budget_pulse/core/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:budget_pulse/main.dart';


void main() {
  late Directory tempDir;
  late Box<TransactionModel> testBox;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionModelAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    testBox = await Hive.openBox<TransactionModel>('test_transactions_box');
  });

  tearDown(() async {
    await testBox.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('BudgetPulseApp renders correctly inside ProviderScope', (WidgetTester tester) async {
    // Wrap BudgetPulseApp in ProviderScope and override the box provider
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionBoxProvider.overrideWithValue(testBox),
        ],
        child: const BudgetPulseApp(),
      ),
    );

    // Verify app boots up successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  test('TransactionNotifier adds and deletes transactions in Hive', () async {
    final container = ProviderContainer(
      overrides: [
        transactionBoxProvider.overrideWithValue(testBox),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(transactionProvider), isEmpty);

    await container.read(transactionProvider.notifier).addTransaction(
          title: 'Coffee Shop',
          amount: 6.50,
          category: 'Food',
          isExpense: true,
        );

    final afterAdd = container.read(transactionProvider);
    expect(afterAdd.length, 1);
    expect(afterAdd.first.title, 'Coffee Shop');

    await container
        .read(transactionProvider.notifier)
        .deleteTransaction(afterAdd.first);

    expect(container.read(transactionProvider), isEmpty);
  });
}