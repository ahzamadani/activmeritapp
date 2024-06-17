import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'LoginPage.dart';
import 'package:flutter/services.dart';

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

  final _formKey = GlobalKey<FormState>();

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      String _email = _emailController.text.trim();
      String _password = _passwordController.text.trim();
      String _name = _nameController.text.trim();
      int _age = int.tryParse(_ageController.text.trim()) ?? 0;
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

        await _firestore.collection('users').doc(_matricNumber).set({
          'email': _email,
          'name': _name,
          'age': _age,
          'gender': _gender,
          'college': _college,
          'matricNumber': _matricNumber,
          'phone': _phone,
          'uid': userCredential.user!.uid,
        });

        debugPrint("User Registered: ${userCredential.user!.email}");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registered Successfully")),
        );

        Navigator.push(
            context, MaterialPageRoute(builder: (context) => LoginPage()));
      } catch (e) {
        debugPrint("Error During Registration: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error During Registration: $e")),
        );
      }
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please fill in your name';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.singleLineFormatter,
                      _CapitalizeWordsTextInputFormatter(),
                    ],
                  ),
                  SizedBox(height: 20.0),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please fill in your email';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20.0),
                  TextFormField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please fill in your age';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Age must be a number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20.0),
                  TextFormField(
                    controller: _genderController,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please fill in your gender';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.singleLineFormatter,
                      _CapitalizeWordsTextInputFormatter(),
                    ],
                  ),
                  SizedBox(height: 20.0),
                  TextFormField(
                    controller: _collegeController,
                    decoration: InputDecoration(
                      labelText: 'College',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please fill in your college';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.singleLineFormatter,
                      _CapitalizeWordsTextInputFormatter(),
                    ],
                  ),
                  SizedBox(height: 20.0),
                  TextFormField(
                    controller: _matricNumberController,
                    decoration: InputDecoration(
                      labelText: 'Matric Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please fill in your matric number';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Matric number must be a number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20.0),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please fill in your phone number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20.0),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please fill in your password';
                      }
                      return null;
                    },
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
      ),
    );
  }
}

class _CapitalizeWordsTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: _capitalizeEachWord(newValue.text),
      selection: newValue.selection,
    );
  }

  String _capitalizeEachWord(String input) {
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
