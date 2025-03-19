import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _titleController = TextEditingController();
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
    if (_titleController.text.isEmpty || _noteController.text.isEmpty) return;
    _notesBox?.add({
      'title': _titleController.text,
      'note': _noteController.text,
      'date': DateTime.now().toString(),
    });
    _titleController.clear();
    _noteController.clear();
    setState(() {});
  }

  void _editNote(int index, String updatedTitle, String updatedNote) {
    _notesBox?.putAt(index, {
      'title': updatedTitle,
      'note': updatedNote,
      'date': DateTime.now().toString(),
    });
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
      return note['title'].toLowerCase().contains(searchQuery) ||
          note['note'].toLowerCase().contains(searchQuery);
    }).toList();
  }

  void _showEditDialog(int index, String currentTitle, String currentNote) {
    TextEditingController titleController = TextEditingController(text: currentTitle);
    TextEditingController noteController = TextEditingController(text: currentNote);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Note"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: noteController,
              decoration: InputDecoration(labelText: 'Note'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _editNote(index, titleController.text, noteController.text);
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
      appBar: AppBar(
        title: Text('Notes'),
        elevation: 0, // Remove app bar shadow
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search notes...",
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          // Notes List
          Expanded(
            child: _notesBox == null
                ? Center(child: CircularProgressIndicator())
                : _filteredNotes().isEmpty
                ? Center(child: Text("No Notes Found", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredNotes().length,
              itemBuilder: (context, index) {
                var note = _filteredNotes()[index];
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      note['title'],
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      "📅 ${note['date']}",
                      style: TextStyle(color: Colors.grey),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          note['note'],
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditDialog(index, note['title'], note['note']),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteNote(index),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Floating Action Button (FAB)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Add Note"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(hintText: "Title"),
                  ),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(hintText: "Note"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    _addNote();
                    Navigator.pop(context);
                  },
                  child: Text("Add"),
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}