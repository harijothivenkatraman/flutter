import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Reminder extends StatefulWidget {
  @override
  _ReminderState createState() => _ReminderState();
}

class _ReminderState extends State<Reminder> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();
  DateTime? _selectedDateTime;
  TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones(); // Initialize timezone

    var androidSettings =
    const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosSettings = const DarwinInitializationSettings();
    var initSettings =
    InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(initSettings);

    print("🔔 Notifications initialized successfully!");
  }

  Future<void> _selectDateTime(BuildContext context) async {
    DateTime now = DateTime.now();

    // Select Date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      // Select Time
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
          print("📅 Selected DateTime: $_selectedDateTime");
        });
      }
    }
  }

  Future<void> _scheduleNotification() async {
    if (_selectedDateTime == null || _noteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Please select date, time & enter a note!"))
      );
      return;
    }

    var androidDetails = const AndroidNotificationDetails(
      'reminder_id', 'Reminder',
      channelDescription: 'Scheduled Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    var iosDetails = const DarwinNotificationDetails();
    var details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Convert to TimeZone aware DateTime
    tz.TZDateTime scheduleTime = tz.TZDateTime.from(_selectedDateTime!, tz.local);

    print("⏳ Scheduling reminder for: $scheduleTime with note: ${_noteController.text}");

    await _notificationsPlugin.zonedSchedule(
      0,
      'Reminder',
      _noteController.text, // Custom Note
      scheduleTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Reminder Set for ${_selectedDateTime!.toString()}"))
    );
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
            ElevatedButton(
              onPressed: _scheduleNotification,
              child: const Text('Set Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
