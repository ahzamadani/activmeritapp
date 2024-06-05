import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:activmerit/HomePage.dart';

class ScanResult extends StatelessWidget {
  final Map<String, dynamic> eventDetails;
  final String activityId;

  const ScanResult(
      {Key? key, required this.eventDetails, required this.activityId})
      : super(key: key);

  Future<void> _registerAttendance(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No authenticated user.'),
          ),
        );
        return;
      }

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: currentUser.email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User data not found.'),
          ),
        );
        return;
      }

      final userData = userSnapshot.docs.first.data();
      final matricNumber = userData['matricNumber'];

      final activityLogSnapshot = await FirebaseFirestore.instance
          .collection('activitylog')
          .doc(activityId)
          .collection('scannedUser')
          .where('matricNumber', isEqualTo: matricNumber)
          .get();

      if (activityLogSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register attendance. Please try again.'),
          ),
        );
        return;
      }

      // The attendance is registered successfully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance registered successfully.'),
        ),
      );

      // Navigate back to the homepage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error occurred: $e'),
        ),
      );
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Result'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Scanned Successfully!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text('Event Name: ${eventDetails['eventName']}'),
            Text('Place Name: ${eventDetails['placeName']}'),
            Text('Date: ${eventDetails['date']}'),
            Text('Start Time: ${eventDetails['startTime']}'),
            Text('End Time: ${eventDetails['endTime']}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _registerAttendance(context),
              child: Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
