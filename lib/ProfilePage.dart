import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'LoginPage.dart';
import 'UpdateProfilePage.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userProfile;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: user!.uid)
          .limit(1)
          .get()
          .then((snapshot) => snapshot.docs.first);

      if (userDoc.exists) {
        String matricNumber =
            (userDoc.data() as Map<String, dynamic>)['matricNumber'];

        DocumentSnapshot userProfileDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(matricNumber)
            .get();

        setState(() {
          userProfile = userProfileDoc.data() as Map<String, dynamic>?;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff717ff5), Color(0xffcfe2ff)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: userProfile == null
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        SizedBox(height: 20),
                        Text(
                          userProfile!['name'] ?? 'No name',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          userProfile!['college'] ?? 'No college',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              ProfileDetailCard(
                                icon: Icons.person_outline,
                                label: 'Name',
                                value: userProfile!['name'] ?? 'No name',
                              ),
                              ProfileDetailCard(
                                icon: Icons.school_outlined,
                                label: 'Matric Number',
                                value: userProfile!['matricNumber'] ??
                                    'No matric number',
                              ),
                              ProfileDetailCard(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: userProfile!['email'] ?? 'No email',
                              ),
                              ProfileDetailCard(
                                icon: Icons.cake_outlined,
                                label: 'Age',
                                value:
                                    userProfile!['age']?.toString() ?? 'No age',
                              ),
                              ProfileDetailCard(
                                icon: Icons.phone_outlined,
                                label: 'Phone Number',
                                value: userProfile!['phone'] ?? 'No phone',
                              ),
                              ProfileDetailCard(
                                icon: Icons.male_outlined,
                                label: 'Gender',
                                value: userProfile!['gender'] ?? 'No gender',
                              ),
                              ProfileDetailCard(
                                icon: Icons.school_outlined,
                                label: 'Current College',
                                value: userProfile!['college'] ?? 'No college',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UpdateProfilePage(
                                    userProfile: userProfile!),
                              ),
                            ).then((_) {
                              _fetchUserProfile();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                          ),
                          child: Text('Update Profile'),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            _showLogoutConfirmation(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xff012970),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                          ),
                          child: Text('Log Out'),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logged out successfully')),
                );
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}

class ProfileDetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileDetailCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueGrey, size: 24),
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey,
              ),
            ),
            Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
