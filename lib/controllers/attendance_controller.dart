import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance_model.dart';

class AttendanceController extends GetxController {
  var name = ''.obs;
  var phone = ''.obs;
  var imageFile = Rxn<File>();
  var location = Rxn<Position>();
  var address = ''.obs;
  var checkInTime = Rxn<DateTime>();
  var checkOutTime = Rxn<DateTime>();

  final picker = ImagePicker();

   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      imageFile.value = File(picked.path);

    }
  }

  Future<void> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) return;
    location.value = await Geolocator.getCurrentPosition();
    address.value = "Lat: ${location.value!.latitude}, Lon: ${location.value!.longitude}";
  }

  /*Future<String> uploadImage(File file) async {
  try {
    if (!file.existsSync()) throw Exception("File does not exist.");
    
    final ref = FirebaseStorage.instance
        .ref()
        .child("selfies/${DateTime.now().millisecondsSinceEpoch}.jpg");

    final uploadTask = await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    print("Upload failed: $e");
    rethrow;
  }
}
*/

Future<String?> uploadImageToSupabase(File imageFile) async {
  final supabase = Supabase.instance.client;
  final fileName = 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

  final fileBytes = await imageFile.readAsBytes();

  final response = await supabase.storage
      .from('selfies') // your bucket name
      .uploadBinary(
        'uploads/$fileName',
        fileBytes,
        fileOptions: FileOptions(contentType: mimeType),
      );

  if (response != null) {
    final imageUrl = supabase.storage
        .from('selfies')
        .getPublicUrl('uploads/$fileName');
    print('✅ Uploaded: $imageUrl');
    return imageUrl;
  } else {
    print('❌ Upload failed');
    return null;
  }
}


 Future<void> checkIn() async {
  if (name.value.isEmpty || phone.value.isEmpty || imageFile.value == null) return;

  try {
    await getLocation();
    checkInTime.value = DateTime.now();

  
    // Wait for image upload to complete before proceeding
    final imageUrl = await uploadImageToSupabase(imageFile.value!);
    print("Image uploaded successfully: $imageUrl");

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final docRef = _firestore
        .collection('attendance')
        .doc(today)
        .collection('checkins')
        .doc(phone.value);

    final model = AttendanceModel(
      name: name.value,
      phone: phone.value,
      imageUrl: imageUrl!,
      latitude: location.value!.latitude,
      longitude: location.value!.longitude,
      address: address.value,
      checkIn: checkInTime.value!,
    );

    await docRef.set(model.toJson());

    Fluttertoast.showToast(
      msg: "Check-in Done!",
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
    name.value = '';
    phone.value='';
    imageFile.value = null;
    print("Check-in saved successfully.");
  } catch (e) {
    print("Failed to save check-in: $e");
    Fluttertoast.showToast(
      msg: "Check-in failed: $e",
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }
}



  
 Future<void> checkOut() async {
  checkOutTime.value = DateTime.now();

  final today = DateTime.now().toIso8601String().substring(0, 10);
  final docRef = FirebaseFirestore.instance
      .collection("attendance")
      .doc(today)
      .collection("checkins")
      .doc(phone.value);

  final doc = await docRef.get();

  if (doc.exists) {
    final checkInTimestamp = doc['checkIn'] != null
        ? (doc['checkIn'] as Timestamp).toDate()
        : DateTime.now();

    await docRef.update({
      "checkOut": checkOutTime.value!.toIso8601String(),
      "workingHours": _getDuration(checkInTimestamp, checkOutTime.value!)
    });
     Fluttertoast.showToast(
  msg: "Check-out updated for ${phone.value}",
  backgroundColor: Colors.green,
  textColor: Colors.white,
  fontSize: 16.0,
);

    print("Check-out updated for ${phone.value}");
  } else {
     Fluttertoast.showToast(
  msg: "No check-in found for today.",
  backgroundColor: Colors.green,
  textColor: Colors.white,
  fontSize: 16.0,
);
    print("No check-in found for today.");
  }
}


  String _getDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    return '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}';
  }
}
