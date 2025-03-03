import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ToDoList extends StatefulWidget {
  @override
  _ToDoListState createState() => _ToDoListState();
}

class _ToDoListState extends State<ToDoList> {
  Box? _todoBox; // Use nullable Box to handle late initialization
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _openBox(); // Open Hive box before accessing it
  }

  Future<void> _openBox() async {
    _todoBox = await Hive.openBox('todoBox');
    setState(() {}); // Update UI after box is opened
  }

  void _addTask() {
    if (_controller.text.isNotEmpty && _todoBox != null) {
      _todoBox!.add(_controller.text);
      _controller.clear();
      setState(() {});
    }
  }

  void _deleteTask(int index) {
    if (_todoBox != null) {
      _todoBox!.deleteAt(index);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('To-Do List')),
      body: _todoBox == null
          ? Center(child: CircularProgressIndicator()) // Show loader until box is ready
          : Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Enter task'),
            ),
          ),
          ElevatedButton(onPressed: _addTask, child: Text('Add Task')),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _todoBox!.listenable(),
              builder: (context, box, _) {
                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(box.getAt(index)),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTask(index),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
