import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  Box? _notesBox;

  @override
  void initState() {
    super.initState();
    _openHiveBox();
  }

  Future<void> _openHiveBox() async {
    _notesBox = await Hive.openBox('notesBox');
    setState(() {});
  }

  void _addNote() {
    if (_noteController.text.isEmpty) return;
    _notesBox?.add({'note': _noteController.text, 'date': DateTime.now().toString()});
    _noteController.clear();
    setState(() {});
  }

  void _editNote(int index, String updatedNote) {
    _notesBox?.putAt(index, {'note': updatedNote, 'date': DateTime.now().toString()});
    setState(() {});
  }

  void _deleteNote(int index) {
    _notesBox?.deleteAt(index);
    setState(() {});
  }

  List<dynamic> _filteredNotes() {
    if (_notesBox == null) return [];
    String searchQuery = _searchController.text.toLowerCase();
    return _notesBox!.values.where((note) {
      return note['note'].toLowerCase().contains(searchQuery);
    }).toList();
  }

  void _showEditDialog(int index, String currentNote) {
    TextEditingController editController = TextEditingController(text: currentNote);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Note"),
        content: TextField(controller: editController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _editNote(index, editController.text);
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notes')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search Notes",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() {}),
            ),
            SizedBox(height: 10),
            Expanded(
              child: _notesBox == null
                  ? Center(child: CircularProgressIndicator())
                  : _filteredNotes().isEmpty
                  ? Center(child: Text("No Notes Found"))
                  : ListView.builder(
                itemCount: _filteredNotes().length,
                itemBuilder: (context, index) {
                  var note = _filteredNotes()[index];
                  return Card(
                    child: ListTile(
                      title: Text(note['note']),
                      subtitle: Text("📅 ${note['date']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditDialog(index, note['note']),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteNote(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: "Write a note",
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addNote,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
