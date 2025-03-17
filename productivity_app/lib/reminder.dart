import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lottie/lottie.dart';

// ✅ Alarm Trigger Function (Must be outside any class)
Future<void> triggerAlarm() async {
  print("🚨 [DEBUG] Alarm Triggered!");

  final AudioPlayer player = AudioPlayer();
  try {
    await player.play(AssetSource('alarm.mp3')); // Ensure the file exists
    print("🔊 [DEBUG] Alarm sound played successfully!");
  } catch (e) {
    print("❌ [ERROR] Failed to play alarm sound: $e");
  }

  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
  await notificationsPlugin.initialize(initSettings);

  var androidDetails = const AndroidNotificationDetails(
    'reminder_id', 'Reminder',
    channelDescription: 'Scheduled Reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  var details = NotificationDetails(android: androidDetails);
  try {
    await notificationsPlugin.show(0, '⏰ Reminder Alert!', 'Your alarm has triggered!', details);
    print("✅ [DEBUG] Notification displayed successfully!");
  } catch (e) {
    print("❌ [ERROR] Failed to show notification: $e");
  }
}

class Reminder extends StatefulWidget {
  @override
  _ReminderState createState() => _ReminderState();
}

class _ReminderState extends State<Reminder> with WidgetsBindingObserver {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final TextEditingController _noteController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _isAlarmRinging = false;
  final AudioPlayer player = AudioPlayer();
  Box? _alarmBox;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeHive();
    _initializeNotifications();
    _rescheduleAlarms();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    player.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _rescheduleAlarms();
    }
  }

  // ✅ Initialize Hive storage
  Future<void> _initializeHive() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    _alarmBox = await Hive.openBox('alarmsBox');
    setState(() {});
  }

  // ✅ Initialize Local Notifications
  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();

    var androidSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosSettings = const DarwinInitializationSettings();
    var initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(initSettings);
  }

  // ✅ Pick Date & Time
  Future<void> _selectDateTime(BuildContext context) async {
    DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute,
          );
        });
      }
    }
  }

  // ✅ Set One-time or Repeating Alarm
  Future<void> _setAlarm({bool repeatDaily = false}) async {
    if (_selectedDateTime == null || _noteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Please select date, time & enter a note!"))
      );
      return;
    }

    int delayInSeconds = _selectedDateTime!.difference(DateTime.now()).inSeconds;
    if (delayInSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Selected time is in the past!"))
      );
      return;
    }

    int alarmId = DateTime.now().millisecondsSinceEpoch % 2147483647;
    print("✅ Alarm ID: $alarmId");
    print("⏳ Delay in seconds: $delayInSeconds");

    bool alarmSet;
    if (repeatDaily) {
      alarmSet = await AndroidAlarmManager.periodic(
        Duration(days: 1),
        alarmId,
        triggerAlarm,
        exact: true,
        wakeup: true,
      );
    } else {
      alarmSet = await AndroidAlarmManager.oneShot(
        Duration(seconds: delayInSeconds),
        alarmId,
        triggerAlarm,
        exact: true,
        wakeup: true,
      );
    }

    if (alarmSet) {
      print("✅ Alarm successfully scheduled!");
    } else {
      print("❌ Alarm scheduling failed!");
    }

    _alarmBox?.add({
      'id': alarmId,
      'time': _selectedDateTime!.toString(),
      'note': _noteController.text,
      'repeat': repeatDaily,
    });

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Alarm set for ${_selectedDateTime!.toString()}"))
    );
  }

  // ✅ Delete Alarm
  Future<void> _deleteAlarm(int index) async {
    var alarm = _alarmBox?.getAt(index);
    if (alarm != null) {
      await AndroidAlarmManager.cancel(alarm['id']);
    }
    await _alarmBox?.deleteAt(index);
    setState(() {});
  }

  // ✅ Snooze Alarm for 5 minutes
  Future<void> _snoozeAlarm() async {
    await player.stop();
    setState(() => _isAlarmRinging = false);

    int snoozeTime = 5 * 60;
    await AndroidAlarmManager.oneShot(
      Duration(seconds: snoozeTime),
      DateTime.now().millisecondsSinceEpoch,
      triggerAlarm,
      exact: true,
      wakeup: true,
    );

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⏰ Snoozed for 5 minutes!"))
    );
  }

  // ✅ Stop Alarm Sound
  Future<void> _stopAlarm() async {
    await player.stop();
    setState(() => _isAlarmRinging = false);
  }

  // ✅ Reschedule Alarms on App Start
  Future<void> _rescheduleAlarms() async {
    if (_alarmBox == null) return;

    for (var i = 0; i < _alarmBox!.length; i++) {
      var alarm = _alarmBox!.getAt(i);
      var alarmTime = DateTime.parse(alarm['time']);
      var delayInSeconds = alarmTime.difference(DateTime.now()).inSeconds;

      if (delayInSeconds > 0) {
        await AndroidAlarmManager.oneShot(
          Duration(seconds: delayInSeconds),
          alarm['id'],
          triggerAlarm,
          exact: true,
          wakeup: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Alarms')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _noteController,
              decoration: InputDecoration(labelText: 'Enter Reminder Note'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _selectDateTime(context),
              child: const Text('Select Date & Time'),
            ),
            SizedBox(height: 10),
            Text(_selectedDateTime == null
                ? "📍 No date/time selected"
                : "🕒 Selected: ${_selectedDateTime!.toLocal()}"),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _setAlarm(repeatDaily: false),
                  child: const Text('Set Alarm'),
                ),
                ElevatedButton(
                  onPressed: () => _setAlarm(repeatDaily: true),
                  child: const Text('Set Daily Alarm'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: _alarmBox == null
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: _alarmBox!.length,
                itemBuilder: (context, index) {
                  var alarm = _alarmBox!.getAt(index);
                  return Card(
                    child: ListTile(
                      title: Text("🕒 ${alarm['time']}"),
                      subtitle: Text("📝 ${alarm['note']}"),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAlarm(index),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isAlarmRinging) ...[
              Lottie.asset('assets/animation/alarm_animation.json', width: 200, height: 200),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: _snoozeAlarm, child: Text("⏳ Snooze")),
                  ElevatedButton(onPressed: _stopAlarm, child: Text("🛑 Stop")),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}