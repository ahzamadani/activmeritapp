import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class UpdateProfilePage extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  UpdateProfilePage({required this.userProfile});

  @override
  _UpdateProfilePageState createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _genderController;
  late TextEditingController _collegeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile['name']);
    _ageController =
        TextEditingController(text: widget.userProfile['age'].toString());
    _phoneController = TextEditingController(text: widget.userProfile['phone']);
    _genderController =
        TextEditingController(text: widget.userProfile['gender']);
    _collegeController =
        TextEditingController(text: widget.userProfile['college']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  Future<void> _updateUserProfile() async {
    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get()
            .then((snapshot) => snapshot.docs.first);

        if (userDoc.exists) {
          String matricNumber =
              (userDoc.data() as Map<String, dynamic>)['matricNumber'];
          bool isChanged = _nameController.text.trim() !=
                  widget.userProfile['name'] ||
              _ageController.text.trim() !=
                  widget.userProfile['age'].toString() ||
              _phoneController.text.trim() != widget.userProfile['phone'] ||
              _genderController.text.trim() != widget.userProfile['gender'] ||
              _collegeController.text.trim() != widget.userProfile['college'];

          if (!isChanged) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Profile details unchanged')),
            );
            return;
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(matricNumber)
              .update({
            'name': _nameController.text.trim(),
            'age': int.tryParse(_ageController.text.trim()),
            'phone': _phoneController.text.trim(),
            'gender': _genderController.text.trim(),
            'college': _collegeController.text.trim(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully!')),
          );

          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Profile'),
      ),
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
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    ProfileUpdateCard(
                      controller: _nameController,
                      label: 'Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    ProfileUpdateCard(
                      controller: _ageController,
                      label: 'Age',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your age';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Age must be a number';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Phone number must be a number without - (dash)';
                        }
                        return null;
                      },
                    ),
                    ProfileUpdateCard(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    ProfileUpdateCard(
                      controller: _genderController,
                      label: 'Gender',
                      icon: Icons.male_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your gender';
                        }
                        return null;
                      },
                    ),
                    ProfileUpdateCard(
                      controller: _collegeController,
                      label: 'Current College',
                      icon: Icons.school_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your current college';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateUserProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                      child: Text('Update Profile'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileUpdateCard extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?) validator;

  ProfileUpdateCard({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    required this.validator,
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
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(labelText: label),
                keyboardType: keyboardType,
                validator: validator,
                textCapitalization: TextCapitalization.words,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.singleLineFormatter,
                  CapitalizeWordsTextInputFormatter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CapitalizeWordsTextInputFormatter extends TextInputFormatter {
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
