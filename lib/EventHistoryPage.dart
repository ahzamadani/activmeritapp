import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EventHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Event History'),
        ),
        body: Center(
          child: Text('No authenticated user.'),
        ),
      );
    }

    final userEmail = user.email;
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: userEmail)
        .limit(1);

    return Scaffold(
      appBar: AppBar(
        title: Text('Event History'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff717ff5), Color(0xffcfe2ff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<QuerySnapshot>(
          future: userRef.get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('User data not found.'));
            }

            final userData = snapshot.data!.docs.first.data()!;
            final matricNumber =
                (userData as Map<String, dynamic>)['matricNumber'] as String;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('activitylog')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No event history found.'));
                }

                // Filter activity logs to find logs where the user's matricNumber is in scannedUser
                final filteredLogsFuture =
                    Future.wait(snapshot.data!.docs.map((log) async {
                  final scannedUserDoc = await log.reference
                      .collection('scannedUser')
                      .doc(matricNumber)
                      .get();
                  return scannedUserDoc.exists ? log : null;
                }).toList());

                return FutureBuilder<List<DocumentSnapshot?>>(
                  future: filteredLogsFuture,
                  builder: (context, filteredSnapshot) {
                    if (filteredSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!filteredSnapshot.hasData ||
                        filteredSnapshot.data!.isEmpty) {
                      return Center(child: Text('No event history found.'));
                    }

                    final filteredLogs = filteredSnapshot.data!
                        .where((log) => log != null)
                        .toList();

                    if (filteredLogs.isEmpty) {
                      return Center(child: Text('No event history found.'));
                    }

                    return ListView.builder(
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index]!;
                        final eventDocRef = log['eventId'] as DocumentReference;
                        final timestamp = log['timestamp'] as Timestamp;
                        final dateTime = timestamp.toDate();

                        return FutureBuilder<DocumentSnapshot>(
                          future: eventDocRef.get(),
                          builder: (context, eventSnapshot) {
                            if (eventSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return ListTile(
                                title: Text('Loading event details...'),
                              );
                            }
                            if (!eventSnapshot.hasData ||
                                !eventSnapshot.data!.exists) {
                              return ListTile(
                                title: Text('Event not found.'),
                              );
                            }

                            final eventData = eventSnapshot.data!.data()!;
                            final eventName = (eventData
                                as Map<String, dynamic>)['eventName'];
                            final placeName = (eventData
                                as Map<String, dynamic>)['placeName'];
                            final startTime = (eventData
                                as Map<String, dynamic>)['startTime'];
                            final endTime =
                                (eventData as Map<String, dynamic>)['endTime'];

                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15.0),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 10.0, sigmaY: 10.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(15.0),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.2)),
                                    ),
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          eventName,
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 8.0),
                                        Text('Place: $placeName',
                                            textAlign: TextAlign.center),
                                        Text('Time: $startTime - $endTime',
                                            textAlign: TextAlign.center),
                                        Text(
                                            '${dateTime.toLocal().toIso8601String().substring(11, 19)}',
                                            textAlign: TextAlign.center),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
