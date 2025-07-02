import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  String name;
  String phone;
  String imageUrl;
  double latitude;
  double longitude;
  String address;
  DateTime checkIn;
  DateTime? checkOut;

  AttendanceModel({
    required this.name,
    required this.phone,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.checkIn,
    this.checkOut,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'checkIn': Timestamp.fromDate(checkIn), // <- Native Firestore Timestamp
'checkOut': checkOut != null ? Timestamp.fromDate(checkOut!) : null,
      'workingHours': checkOut != null
          ? _getDuration(checkIn, checkOut!)
          : null,
    };
  }

  String _getDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    return '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}';
  }
}
