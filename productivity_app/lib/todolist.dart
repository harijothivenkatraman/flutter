import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';


import 'main.dart';

class ToDoList extends StatefulWidget {
  @override
  _ToDoListState createState() => _ToDoListState();
}

class _ToDoListState extends State<ToDoList> {
  Box? _todoBox;
  final TextEditingController _controller = TextEditingController();
  DateTime? _selectedTime;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _openBox();
    AndroidAlarmManager.initialize();
  }
  Future<void> _requestPermissions() async {
    if (await Permission.scheduleExactAlarm.request().isGranted) {
      print("Exact Alarm Permission Granted");
    } else {
      print("Exact Alarm Permission Denied");
    }
  }

  Future<void> _openBox() async {
    _todoBox = await Hive.openBox('todoBox');
    setState(() {});
  }

  void _addTask(String task, DateTime? reminderTime) {
    if (task.isNotEmpty && _todoBox != null) {
      int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      _todoBox!.add({
        'task': task,
        'completed': false,
        'reminderTime': reminderTime?.toIso8601String(),
        'id': id
      });

      if (reminderTime != null) {
        scheduleNotification(id, task, reminderTime);
        scheduleAlarm(id, task, reminderTime);
      }

      _controller.clear();
      setState(() {});
    }
  }

  void _toggleTask(int index) {
    var task = _todoBox!.getAt(index);
    if (task is Map) {
      _todoBox!.putAt(index, {
        'task': task['task'],
        'completed': !task['completed'],
        'reminderTime': task['reminderTime'],
        'id': task['id']
      });
      setState(() {});
    }
  }

  void _deleteTask(int index) {
    var task = _todoBox!.getAt(index);
    if (task is Map) {
      int id = task['id'];
      flutterLocalNotificationsPlugin.cancel(id);
      AndroidAlarmManager.cancel(id);
    }
    _todoBox!.deleteAt(index);
    setState(() {});
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      DateTime now = DateTime.now();
      _selectedTime =
          DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      setState(() {});
    }
  }

  void scheduleNotification(int id, String task, DateTime dateTime) async {
    var androidDetails = AndroidNotificationDetails(
      'task_reminder',
      'Task Reminder',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm_sound'), // ✅ Use file name without extension
    );

    var notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Task Reminder',
      task,
      tz.TZDateTime.from(dateTime, tz.local),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  void scheduleAlarm(int id, String task, DateTime dateTime) async {
    await AndroidAlarmManager.oneShotAt(
      dateTime,
      id,
      alarmCallback,
      exact: true,
      wakeup: true,
    );
  }

  static void alarmCallback() {
    flutterLocalNotificationsPlugin.show(
      0,
      '⏰ Alarm Ringing!',
      'Your scheduled task is due!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Alarm Channel',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('alarm_sound'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_todoBox == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('To-Do List with Alarms & Notifications')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter task...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: () => _selectTime(context),
                ),
                ElevatedButton(
                  onPressed: () => _addTask(_controller.text, _selectedTime),
                  child: Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _todoBox!.listenable(),
              builder: (context, box, _) {
                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    var task = box.getAt(index);

                    if (task is! Map || !task.containsKey('task')) {
                      return SizedBox();
                    }

                    String? reminderTime = task['reminderTime'];
                    DateTime? reminderDateTime =
                    reminderTime != null ? DateTime.parse(reminderTime) : null;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      elevation: 2,
                      child: ListTile(
                        leading: Checkbox(
                          value: task['completed'],
                          onChanged: (_) => _toggleTask(index),
                        ),
                        title: Text(
                          task['task'],
                          style: TextStyle(
                            decoration: task['completed']
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: reminderDateTime != null
                            ? Text(
                            'Reminder: ${reminderDateTime.hour}:${reminderDateTime.minute}')
                            : null,
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTask(index),
                        ),
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
