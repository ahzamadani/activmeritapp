import 'package:activmerit/colors.dart';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:activmerit/HomePage.dart';

class GenerateQR extends StatelessWidget {
  final String eventId;
  final String eventDetails;

  const GenerateQR(
      {Key? key, required this.eventId, required this.eventDetails})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code'),
        backgroundColor: backgroundColor1,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.all(20.0),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      spreadRadius: 1.0,
                    ),
                  ],
                ),
                child: PrettyQr(
                  data: eventId, // QR code data is the event ID
                  size: 200,
                  roundEdges: true,
                ),
              ),
              SizedBox(height: 20),
              Text(
                eventDetails,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                child: Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
