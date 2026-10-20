import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';


import 'package:hive_flutter/hive_flutter.dart'; // for local storage
// import 'package:path_provider/path_provider.dart';
// import 'core/router/app_router.dart';
// import 'core/theme/app_theme.dart';
import  'core/features/transactions/data/models/transaction_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

// Global provider to expose the active Isar instance across the app
final transactionBoxProvider = Provider<Box<TransactionModel>>((ref) => throw UnimplementedError());


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load the .env file
  await dotenv.load(fileName: ".env");
  // Initialize Hive for Flutter local storage directory management
  await Hive.initFlutter();
  // Register the auto-generated type adapter
  Hive.registerAdapter(TransactionModelAdapter());

  // Open a secure local box specifically for transactions
  final transactionBox = await Hive.openBox<TransactionModel>('transactions_box');


  runApp(
    ProviderScope(
      overrides: [
        // Override the placeholder provider with our active Hive box
        transactionBoxProvider.overrideWithValue(transactionBox),
      ],
      child: const BudgetPulseApp(),
    ),
  );
}


class BudgetPulseApp extends ConsumerWidget {
  const BudgetPulseApp({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'BudgetPulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Enforcing modern dark-first design
      routerConfig: router,

    );
  }
}