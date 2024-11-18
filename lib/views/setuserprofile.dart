import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SetDisplayNamePage extends StatefulWidget {
  final User user;

  const SetDisplayNamePage({Key? key, required this.user}) : super(key: key);

  @override
  _SetDisplayNamePageState createState() => _SetDisplayNamePageState();
}

class _SetDisplayNamePageState extends State<SetDisplayNamePage> {
  final TextEditingController _displayNameController = TextEditingController();
  
  final TextEditingController _phoneNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _image;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _setProfile(String displayName, String phoneNumber) async {
    setState(() {
      _isLoading = true;
    });

    String? photoURL;

    if (_image != null) {
      final storageRef = FirebaseStorage.instance.ref().child('profile_pictures').child(widget.user.uid);
      await storageRef.putFile(_image!);
      photoURL = await storageRef.getDownloadURL();
    }


    await widget.user.updateDisplayName(displayName);

    await widget.user.updatePhotoURL(photoURL);

    await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
      'displayName': displayName,
      'email': widget.user.email,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
    });

    setState(() {
      _isLoading = false;
    });

    Navigator.of(context).pushReplacementNamed('/home'); // Redirect to home page after setting profile
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Profile'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF6C63FF)),
        titleTextStyle: const TextStyle(color: Color(0xFF6C63FF), fontSize: 20, fontWeight: FontWeight.bold),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.white, 
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _image != null
                            ? FileImage(_image!)
                            : const AssetImage('assets/default_profile.png') as ImageProvider,
                        child: _image == null ? const Icon(Icons.camera_alt, size: 50) : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        prefixIcon: Icon(Icons.person), 
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Display name cannot be empty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone), 
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Phone number cannot be empty';
                        }
                        if (value.length < 11) {
                          return 'Phone number must be at least 11 digits';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'Phone number can only contain digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          final displayName = _displayNameController.text;
                          final phoneNumber = _phoneNumberController.text;
                          await _setProfile(displayName, phoneNumber);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
