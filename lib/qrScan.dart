import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:activmerit/HomePage.dart';
import 'package:activmerit/ScanResult.dart';

class QRScan extends StatefulWidget {
  const QRScan({Key? key}) : super(key: key);

  @override
  _QRScanState createState() => _QRScanState();
}

class _QRScanState extends State<QRScan> {
  @override
  void initState() {
    super.initState();
    _scanQR();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Future<void> _scanQR() async {
    try {
      String eventId = await FlutterBarcodeScanner.scanBarcode(
        '#4154f1', // Color for the scanner
        'Cancel', // Text for the cancel button
        true, // Show flash icon
        ScanMode.QR, // Scan mode QR
      );

      if (eventId == '-1') {
        // If the scan is canceled (FlutterBarcodeScanner returns '-1' on cancel)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
        return;
      }

      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No authenticated user.'),
          ),
        );
        return;
      }

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User not found.'),
          ),
        );
        return;
      }

      final userData = userSnapshot.docs.first.data();
      final matricNumber = userData['matricNumber'];
      final userName = userData['name'];
      final college = userData['college'];

      final eventDocRef =
          FirebaseFirestore.instance.collection('events').doc(eventId);
      final eventDetailsSnapshot = await eventDocRef.get();
      if (!eventDetailsSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event not found.'),
          ),
        );
        return;
      }

      final eventDetails = eventDetailsSnapshot.data()!;

      // Find the existing activityId with the same eventId
      final activityLogSnapshot = await FirebaseFirestore.instance
          .collection('activitylog')
          .where('eventId', isEqualTo: eventDocRef)
          .limit(1)
          .get();

      if (activityLogSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Activity log not found.'),
          ),
        );
        return;
      }

      final activityId = activityLogSnapshot.docs.first.id;

      // Check if the user has already scanned the event
      final scannedUserSnapshot = await FirebaseFirestore.instance
          .collection('activitylog')
          .doc(activityId)
          .collection('scannedUser')
          .doc(matricNumber)
          .get();

      if (scannedUserSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance is already scanned.'),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
        return;
      }

      // Store the scanned user details in a nested collection
      await FirebaseFirestore.instance
          .collection('activitylog')
          .doc(activityId)
          .collection('scannedUser')
          .doc(matricNumber)
          .set({
        'name': userName,
        'college': college,
        'matricNumber': matricNumber,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanResult(
            eventDetails: eventDetails as Map<String, dynamic>,
            activityId: activityId,
          ),
        ),
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
}
