import 'package:flutter/material.dart';
import 'package:expense_tracker_app/models/expense.dart';
import 'package:expense_tracker_app/services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpenseSummary extends StatefulWidget {
  const ExpenseSummary({Key? key}) : super(key: key);

  @override
  State<ExpenseSummary> createState() => _ExpenseSummaryState();
}

class _ExpenseSummaryState extends State<ExpenseSummary> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Expense> _expenses = [];
  String _selectedPeriod = 'Weekly';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    _firebaseService.getExpenses().listen((expenses) {
      setState(() {
        _expenses = expenses;
      });
    });
  }

  double getTotalExpensesForPeriod(String period) {
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'Weekly':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Monthly':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Yearly':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = now;
    }

    double total = 0;
    for (var expense in _expenses) {
      if (expense.date.isAfter(startDate.subtract(const Duration(days: 1)))) {
        total += expense.amount;
      }
    }
    return total;
  }

  Map<String, double> getCategoryTotalsForPeriod(String period) {
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'Weekly':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Monthly':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Yearly':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = now;
    }

    Map<String, double> categoryTotals = {};
    for (var expense in _expenses) {
      if (expense.date.isAfter(startDate.subtract(const Duration(days: 1)))) {
        if (categoryTotals.containsKey(expense.category)) {
          categoryTotals[expense.category] =
              categoryTotals[expense.category]! + expense.amount;
        } else {
          categoryTotals[expense.category] = expense.amount;
        }
      }
    }
    return categoryTotals;
  }

  List<PieChartSectionData> getChartData() {
    final categoryTotals = getCategoryTotalsForPeriod(_selectedPeriod);
    List<PieChartSectionData> chartData = [];

    categoryTotals.forEach((category, total) {
      chartData.add(
        PieChartSectionData(
          color: getColorForCategory(category),
          value: total,
          title: category,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return chartData;
  }

  Color getColorForCategory(String category) {
    switch (category) {
      case 'Food':
        return Colors.red;
      case 'Transportation':
        return Colors.green;
      case 'Entertainment':
        return Colors.blue;
      case 'Utilities':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedPeriod,
              items: <String>['Weekly', 'Monthly', 'Yearly']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPeriod = newValue!;
                });
              },
            ),
            Text(
              'Total Expenses (${_selectedPeriod}): \$${getTotalExpensesForPeriod(_selectedPeriod).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: getChartData(),
                  centerSpaceRadius: 40,
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Category-wise Expenses:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ...getCategoryTotalsForPeriod(_selectedPeriod).entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${entry.key}:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${entry.value.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}