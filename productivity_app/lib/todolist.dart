import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void alarmCallback() async {
  final plugin = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await plugin.initialize(initSettings);

  await plugin.show(
    0,
    '⏰ Alarm',
    'Time to do your task!',
    NotificationDetails(
      android: AndroidNotificationDetails(
        'alarm_channel',
        'Alarm Notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
  );
}


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
    _initializePlugins();
    _openBox();
  }

  Future<void> _initializePlugins() async {
    tz.initializeTimeZones();
    await AndroidAlarmManager.initialize();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.scheduleExactAlarm.request();
    if (status.isGranted) {
      print("Exact Alarm Permission Granted");
      // Only schedule test alarm after permission is granted
      await AndroidAlarmManager.oneShotAt(
        DateTime.now().add(Duration(seconds: 30)),
        1234, // alarm ID
        alarmCallback,
        exact: true,
        wakeup: true,
      );
    } else {
      print("Exact Alarm Permission Denied");
      // Show dialog or message about needing permission
    }
  }

  Future<void> _openBox() async {
    _todoBox = await Hive.openBox('todoBox');
    setState(() {});
  }

  void _addTask(String task, DateTime? reminderTime) {
    if (task.isNotEmpty && _todoBox != null) {
      int id = _todoBox!.length + 1;

      // Ensure future reminder
      if (reminderTime != null && reminderTime.isBefore(DateTime.now())) {
        reminderTime = reminderTime.add(Duration(days: 1));
      }

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
      _selectedTime = null;
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
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      AndroidNotificationChannel(
        'alarm_channel',
        'Alarm Notifications',
        description: 'This channel is used for alarm notifications',
        importance: Importance.max,
      ),
    );
  }


  void scheduleNotification(int id, String task, DateTime dateTime) async {
    var androidDetails = AndroidNotificationDetails(
      'task_reminder',
      'Task Reminder',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
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
                            'Reminder: ${reminderDateTime.hour.toString().padLeft(2, '0')}:${reminderDateTime.minute.toString().padLeft(2, '0')}')
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
