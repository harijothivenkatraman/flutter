import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Calculator(),
    );
  }
}

class Calculator extends StatefulWidget {
  const Calculator({super.key});

  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  final CalculatorLogic _calculatorLogic = CalculatorLogic();
  String _display = '0';
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('history')
        .orderBy('timestamp', descending: true)
        .get();
    final List<String> history = snapshot.docs.map((doc) => doc['operation'] as String).toList();
    setState(() {
      _history = history;
    });
  }

  void _onPressed(String value) {
    setState(() {
      _display = _calculatorLogic.calculate(value);
    });
  }

  void _clear() {
    setState(() {
      _display = _calculatorLogic.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Calculator'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('History'),
                    content: _history.isEmpty
                        ? const Text('No history available')
                        : SingleChildScrollView(
                      child: ListBody(
                        children: _history.map((operation) => Text(operation)).toList(),
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Close'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(24),
              child: Text(
                _display,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _buildButtonRow(['7', '8', '9', '/']),
          _buildButtonRow(['4', '5', '6', '*']),
          _buildButtonRow(['1', '2', '3', '-']),
          _buildButtonRow(['0', '.', '=', '+']),
          _buildButtonRow(['C']),
        ],
      ),
    );
  }

  Widget _buildButtonRow(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: values.map((value) {
        return CalculatorButton(
          value: value,
          onPressed: value == 'C' ? _clear : () => _onPressed(value),
        );
      }).toList(),
    );
  }
}

class CalculatorButton extends StatelessWidget {
  final String value;
  final VoidCallback onPressed;

  const CalculatorButton(
      {required this.value, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(
            value,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}

class CalculatorLogic {
  String _operand1 = '';
  String _operand2 = '';
  String _operator = '';
  String _display = '0';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String calculate(String value) {
    if (value == '+' || value == '-' || value == '*' || value == '/') {
      _operator = value;
      _display = '$_operand1 $_operator';
    } else if (value == '=') {
      double num1 = double.parse(_operand1);
      double num2 = double.parse(_operand2);
      double result;

      switch (_operator) {
        case '+':
          result = num1 + num2;
          break;
        case '-':
          result = num1 - num2;
          break;
        case '*':
          result = num1 * num2;
          break;
        case '/':
          result = num1 / num2;
          break;
        default:
          result = 0.0;
      }

      _operand1 = result.toString();
      _operand2 = '';
      _operator = '';
      _display = _operand1;

      // Record history
      _recordHistory('$_operand1 $_operator $_operand2 = $result');
    } else {
      if (_operator.isEmpty) {
        _operand1 += value;
        _display = _operand1;
      } else {
        _operand2 += value;
        _display = '$_operand1 $_operator $_operand2';
      }
    }
    return _display;
  }

  String clear() {
    _operand1 = '';
    _operand2 = '';
    _operator = '';
    _display = '0';
    return _display;
  }

  void _recordHistory(String operation) {
    _firestore.collection('history').add({
      'operation': operation,
      'timestamp': Timestamp.now(),
    }).catchError((error) {
      print("Failed to add history: $error");
      return null;
    });
  }

}



