import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:activmerit/colors.dart';
import 'package:activmerit/LoginPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'package:activmerit/authentication_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .then(
    (FirebaseApp value) => Get.put(AuthenticationRepository()),
  );
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Activ-Merit',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: backgroundColor1),
          useMaterial3: true,
        ),
        home: LoginPage());
  }
}
