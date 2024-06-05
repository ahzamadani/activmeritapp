import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'LoginPage.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _matricNumberController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  Future<void> _handleSignup() async {
    String _email = _emailController.text.trim();
    String _password = _passwordController.text.trim();
    String _name = _nameController.text.trim();
    int _age =
        int.tryParse(_ageController.text.trim()) ?? 0; // Parse age as integer
    String _gender = _genderController.text.trim();
    String _college = _collegeController.text.trim();
    String _matricNumber = _matricNumberController.text.trim();
    String _phone = _phoneController.text.trim();

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      // Save user data to Firestore with matricNumber as document ID
      await _firestore.collection('users').doc(_matricNumber).set({
        'email': _email,
        'name': _name,
        'age': _age,
        'gender': _gender,
        'college': _college,
        'matricNumber': _matricNumber,
        'phone': _phone,
        'uid': userCredential.user!.uid, // Store the Firebase Auth UID
      });

      debugPrint("User Registered: ${userCredential.user!.email}");
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => LoginPage()));
    } catch (e) {
      debugPrint("Error During Registration: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff717ff5), Color(0xffcfe2ff)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: _genderController,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: _collegeController,
                  decoration: InputDecoration(
                    labelText: 'College',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: _matricNumberController,
                  decoration: InputDecoration(
                    labelText: 'Matric Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _handleSignup,
                  child: Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
