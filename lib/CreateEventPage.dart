import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'GenerateQR.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:activmerit/colors.dart';
import 'utils.dart'; // Import the utility function

class CreateEventPage extends StatefulWidget {
  @override
  _CreateEventPageState createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _eventNameController = TextEditingController();
  final _placeNameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();
  String _checkInOut = 'IN/OUT';

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (pickedTime != null && pickedTime != _startTime) {
      setState(() {
        _startTime = pickedTime;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (pickedTime != null && pickedTime != _endTime) {
      setState(() {
        _endTime = pickedTime;
      });
    }
  }

  Future<int> _getMerit() async {
    try {
      final meritSnapshot = await FirebaseFirestore.instance
          .collection('merit')
          .doc('defaultMerit')
          .get();
      if (meritSnapshot.exists) {
        final meritData = meritSnapshot.data() as Map<String, dynamic>;
        return meritData['value'] ?? 1;
      } else {
        return 1;
      }
    } catch (e) {
      print('Error fetching merit: $e');
      return 1;
    }
  }

  Future<void> _createEvent() async {
    String eventName = _eventNameController.text.trim();
    String placeName = _placeNameController.text.trim();

    if (eventName.isEmpty || placeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in the event details')),
      );
      return;
    }

    String eventId = Uuid().v4();
    String date = _selectedDate.toString().substring(0, 10);
    String startTime = '${_startTime.format(context)}';
    String endTime = '${_endTime.format(context)}';
    String eventDetails = 'Event Name: $eventName\n'
        'Place Name: $placeName\n'
        'Date: $date\n'
        'Start Time: $startTime\n'
        'End Time: $endTime\n'
        'Check: $_checkInOut';

    int merit = await _getMerit();

    // Save the event details to Firestore
    DocumentReference eventRef =
        FirebaseFirestore.instance.collection('events').doc(eventId);
    await eventRef.set({
      'eventName': eventName,
      'placeName': placeName,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'checkInOut': _checkInOut,
      'merit': merit, // Fetch merit value from Firestore or use default
    });

    // Generate activity log ID
    String activityId = await generateActivityLogId();

    // Save event details to activity log with event reference
    await FirebaseFirestore.instance
        .collection('activitylog')
        .doc(activityId)
        .set({
      'eventId': eventRef,
      'eventName': eventName,
      'placeName': placeName,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'checkInOut': _checkInOut,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Navigate to the QR code page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GenerateQR(eventDetails: eventDetails, eventId: eventId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text('Create Event'),
        backgroundColor: backgroundColor1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _eventNameController,
                decoration: InputDecoration(
                  labelText: 'Event Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _placeNameController,
                decoration: InputDecoration(
                  labelText: 'Place Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '${_selectedDate.toString().substring(0, 10)}'),
                            Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectStartTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Starts',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_startTime.format(context)}'),
                            Icon(Icons.access_time),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _checkInOut,
                      decoration: InputDecoration(
                        labelText: 'Check',
                        border: OutlineInputBorder(),
                      ),
                      items: ['IN/OUT', 'IN', 'OUT']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _checkInOut = newValue!;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectEndTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Ends',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_endTime.format(context)}'),
                            Icon(Icons.access_time),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorButton,
                  foregroundColor: backgroundTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text('GENERATE QR CODE', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
