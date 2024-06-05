import 'package:cloud_firestore/cloud_firestore.dart';

Future<String> generateActivityLogId() async {
  final snapshot =
      await FirebaseFirestore.instance.collection('activitylog').get();
  List<int> existingIds = snapshot.docs.map((doc) => int.parse(doc.id)).toList()
    ..sort();

  for (int i = 0; i < existingIds.length; i++) {
    if (existingIds[i] != i + 1) {
      return (i + 1).toString().padLeft(5, '0');
    }
  }
  return (existingIds.length + 1).toString().padLeft(5, '0');
}
