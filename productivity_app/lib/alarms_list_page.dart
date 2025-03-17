import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AlarmsListPage extends StatefulWidget {
  @override
  _AlarmsListPageState createState() => _AlarmsListPageState();
}

class _AlarmsListPageState extends State<AlarmsListPage> {
  late Box alarmBox;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    alarmBox = await Hive.openBox('alarmsBox');
    setState(() {}); // Refresh UI after loading data
  }

  Future<void> _deleteAlarm(int index) async {
    await alarmBox.deleteAt(index);
    setState(() {}); // Refresh after deletion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scheduled Alarms")),
      body: alarmBox == null || alarmBox.isEmpty
          ? Center(child: Text("No Alarms Scheduled"))
          : ListView.builder(
        itemCount: alarmBox.length,
        itemBuilder: (context, index) {
          var alarm = alarmBox.getAt(index);
          return ListTile(
            title: Text("⏰ ${alarm['time']}"),
            subtitle: Text("📌 Note: ${alarm['note']}"),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteAlarm(index),
            ),
          );
        },
      ),
    );
  }
}
