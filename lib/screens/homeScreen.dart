import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/attendance_controller.dart';

class HomeScreen extends StatefulWidget {
   const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
   final controller = Get.put(AttendanceController());
    final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
   

    return Scaffold(
      appBar: AppBar(title: const Text("Employee Check-In")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name Field
              TextFormField(
                decoration: const InputDecoration(labelText: "Full Name"),
                onChanged: (val) => controller.name.value = val,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),

              // Phone Field
              TextFormField(
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
                onChanged: (val) => controller.phone.value = val,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  } else if (!RegExp(r'^[1-9]\d{9}$').hasMatch(value)) {
                    return 'Enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),
                Obx(() => controller.imageFile.value != null
                  ? Container(
                    height: Get.height * 0.3,
                    width: Get.width * 0.8,
                    child: Image.file(controller.imageFile.value!, height: 100))
                  : const Text("No Image")),

            

              ElevatedButton(
                onPressed: () => controller.pickImage(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt),
                    SizedBox(width: 10),
                    Text("Take Selfie"),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: ()async {
                      if (_formKey.currentState!.validate()) {
                        if(controller.imageFile.value == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please take a selfie"))
                          );
                          return;
                        }
                        print('checkin pressed');
                         await controller.checkIn();
                        
                      }
                    },
                    child: const Text("Check In"),
                  ),
                   ElevatedButton(
                onPressed: ()async  => await controller.checkOut(),
                child: const Text("Check Out"),
              ),
                ],
              ),

             
            ],
          ),
        ),
      ),
    );
  }
}
