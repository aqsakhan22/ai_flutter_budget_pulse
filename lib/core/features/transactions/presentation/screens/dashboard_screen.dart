
import 'package:budget_pulse/core/features/transactions/data/services/receipt_ai_service.dart';
import 'package:budget_pulse/core/features/transactions/presentation/widgets/spending_chart_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Correct

class DashboardScreen extends ConsumerWidget{
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: implement build
// Watch the live transaction list from our Riverpod provider
    final transactions = ref.watch(transactionProvider);
    // Calculate total income and expenses dynamically
    double totalIncome = transactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    double totalExpense = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    double netBalance = totalIncome - totalExpense;



    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      floatingActionButton: FloatingActionButton(
      backgroundColor: const Color(0xFF4F46E5),
      child: const Icon(Icons.add, color: Colors.white),
      onPressed: () {
        // Trigger the modal bottom sheet function
        _showAddTransactionSheet(context);
      },
    ),
      body: SingleChildScrollView(
       
        child: 
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: 
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
  'Welcome Back,',
  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14), // Replaced Colors.slate with proper hex slate color
),
                      Text(
                        'BudgetPulse',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                CircleAvatar(
                    backgroundColor: const Color(0xFF1E293B),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),

              ],
            ),

            // Main Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${netBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryIndicator('Income', '+\$${totalIncome.toStringAsFixed(2)}', Colors.greenAccent),
                        _buildSummaryIndicator('Expense', '-\$${totalExpense.toStringAsFixed(2)}', Colors.redAccent),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
// Add the Analytics Chart Card here, passing live transactions
SpendingChartCard(transactions: transactions),
// Add this inside your DashboardScreen Column children list
const SizedBox(height: 16),

SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF4F46E5), // Indigo brand color
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    icon: const Icon(Icons.camera_alt_outlined),
    label: const Text(
      'Scan Receipt with AI',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
    onPressed: () async {

      // 1. Initialize the AI service
      final aiService = ReceiptAiService();

      // 2. Open the camera to capture a photo of the receipt
  final imageFile = await aiService.captureReceipt();

  if (imageFile != null) {
    // Show a loading indicator if desired
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analyzing receipt with AI...')),
    );

    // 3. Retrieve your secure API key from dotenv
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    // 4. Send image to Gemini API for parsing
    final parsedData = await aiService.parseReceiptWithAI(imageFile, apiKey);

    if (parsedData != null) {
      // 5. Save the parsed data directly to your Hive database via Riverpod
      ref.read(transactionProvider.notifier).addTransaction(
        title: parsedData['title'] ?? 'Scanned Receipt',
        amount: (parsedData['amount'] as num).toDouble(),
        category: parsedData['category'] ?? 'Shopping',
        isExpense: true, // Receipts are typically expenses
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt successfully scanned and added!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to parse receipt. Please try again.')),
      );
    }
  }

      
      

    
    },
  ),
),



const SizedBox(height: 24),
              // Section Title
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];

                    return 
                    Dismissible(
                      key: ValueKey(tx.transactionId),
                      direction: DismissDirection.endToStart,
  background: Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.redAccent.withOpacity(0.85),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.delete_outline, color: Colors.white),
  ),
  onDismissed: (_) {
    ref.read(transactionProvider.notifier).deleteTransaction(tx);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${tx.title} deleted')),
    );
  },

                     child:  Container(
                  margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),

                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: tx.isExpense
                              ? Colors.red.withOpacity(0.2)
                              : Colors.green.withOpacity(0.2),
                          child: Icon(
                            tx.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                            color: tx.isExpense ? Colors.redAccent : Colors.greenAccent,
                          ),
                        ),

                        title: Text(
                          tx.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          tx.category,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: Text(
                          '${tx.isExpense ? '-' : '+'}\$${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: tx.isExpense ? Colors.redAccent : Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ));
                   

                  }

                ),
              )
            
          ],
        ),
        
        )),
    );

   
  }

}


void _showAddTransactionSheet(BuildContext context) {
showModalBottomSheet(
  context: context,
 
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E293B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
 builder: (context){

  return Padding(
    padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: const AddTransactionForm(),
        );
 });

}

class AddTransactionForm extends ConsumerStatefulWidget {
  const AddTransactionForm({super.key});
@override
  ConsumerState<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends ConsumerState<AddTransactionForm> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  bool _isExpense = true;

  final List<String> _categories = ['Food', 'Income', 'Transport', 'Utilities', 'Entertainment'];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return  SingleChildScrollView(

      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Transaction',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Title Input Field
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Title (e.g., Grocery Store)',
              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),

          // Amount Input Field
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Amount (\$)',
              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          // Type Selector (Expense vs Income)
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Expense'),
                  selected: _isExpense,
                  selectedColor: Colors.redAccent.withOpacity(0.3),
                  onSelected: (selected) => setState(() => _isExpense = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Income'),
                  selected: !_isExpense,
                  selectedColor: Colors.greenAccent.withOpacity(0.3),
                  onSelected: (selected) => setState(() => _isExpense = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category Dropdown
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            dropdownColor: const Color(0xFF0F172A),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Category',
              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: _categories.map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat));
            }).toList(),
            onChanged: (val) => setState(() => _selectedCategory = val!),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final title = _titleController.text.trim();
                final amount = double.tryParse(_amountController.text) ?? 0.0;

                if (title.isNotEmpty && amount > 0) {
                  // Create new item object
                 

                  // Dispatch via Riverpod notifier
                  // Dispatch via Riverpod notifier using named parameters
ref.read(transactionProvider.notifier).addTransaction(
  title: title,
  amount: amount,
  category: _selectedCategory,
  isExpense: _isExpense,
);

                  // Close bottom sheet
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Transaction', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),

        ],
      )

      
    );
  }
}

Widget _buildSummaryIndicator(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(amount, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
