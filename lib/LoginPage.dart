import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:activmerit/HomePage.dart';
import 'package:activmerit/colors.dart';
import 'package:activmerit/SignUpPage.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _matricNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signInWithMatricNumberAndPassword() async {
    String matricNumber = _matricNumberController.text.trim();
    String password = _passwordController.text.trim();

    if (matricNumber.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Insert your matric number and your password")),
      );
      return;
    }

    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(matricNumber)
          .get();

      if (!userSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No user found for that matric number")),
        );
        return;
      }

      String email = (userSnapshot.data() as Map<String, dynamic>)['email'];

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Successfully logged in")),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No user found for that matric number")),
        );
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Wrong password for this matric user")),
        );
      } else if (e.code == 'invalid-credential' || e.code == 'invalid-email') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Wrong password for this matric user")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff717ff5), Color(0xffcfe2ff)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Activ-Merit',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff012970),
                  ),
                ),
                Text(
                  'Login Page',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textButtonColor,
                  ),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: _matricNumberController,
                  decoration: InputDecoration(
                    labelText: 'Matric Number',
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xff012970),
                      ),
                    ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorButton,
                    foregroundColor: backgroundTextColor,
                  ),
                  onPressed: _signInWithMatricNumberAndPassword,
                  child: Text('Login'),
                ),
                SizedBox(height: 20.0),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpPage()),
                    );
                  },
                  child: Text('Don\'t have an account? Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
