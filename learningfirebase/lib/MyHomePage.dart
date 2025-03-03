import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    _updateCounterInFirestore();
  }

  Future<void> _updateCounterInFirestore() async {
    await FirebaseFirestore.instance
        .collection('counters')
        .doc('myCounter')
        .set({'count': _counter});
  }

  @override
  void initState() {
    super.initState();
    _loadCounterFromFirestore();
  }

  Future<void> _loadCounterFromFirestore() async {
    DocumentSnapshot document = await FirebaseFirestore.instance
        .collection('counters')
        .doc('myCounter')
        .get();
    if (document.exists) {
      setState(() {
        _counter = document['count'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
