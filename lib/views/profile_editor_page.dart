import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user_model.dart';

class ProfileEditorPage extends StatefulWidget {
  final UserModel userModel;

  const ProfileEditorPage({Key? key, required this.userModel}) : super(key: key);

  @override
  _ProfileEditorPageState createState() => _ProfileEditorPageState();
}

class _ProfileEditorPageState extends State<ProfileEditorPage> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _image;

  @override
  void initState() {
    super.initState();
    _displayNameController.text = widget.userModel.displayName;
    _phoneNumberController.text = widget.userModel.phoneNumber ?? '';
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile(String newName, String newPhoneNumber) async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    String? photoURL;

    if (user != null) {
      // Delete the old image if it exists
      if (widget.userModel.photoURL != null) {
        final oldImageRef = FirebaseStorage.instance.refFromURL(widget.userModel.photoURL!);
        await oldImageRef.delete();
      }

      // Upload the new image
      if (_image != null) {
        final storageRef = FirebaseStorage.instance.ref().child('profile_pictures').child(user.uid);
        await storageRef.putFile(_image!);
        photoURL = await storageRef.getDownloadURL();
      }

      await user.updateDisplayName(newName);
      await user.updatePhotoURL(photoURL);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'displayName': newName,
        'photoURL': photoURL,
        'phoneNumber': newPhoneNumber,
      });
    }

    setState(() {
      _isLoading = false;
    });

    Navigator.of(context).pop(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF6C63FF)),
        titleTextStyle: const TextStyle(color: Color(0xFF6C63FF), fontSize: 20, fontWeight: FontWeight.bold),
        elevation: 0,
        automaticallyImplyLeading: true, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: Colors.white, 
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                            : (widget.userModel.photoURL != null
                                ? NetworkImage(widget.userModel.photoURL!)
                                : const AssetImage('assets/default_profile.png')) as ImageProvider,
                        child: _image == null && widget.userModel.photoURL == null
                            ? const Icon(Icons.camera_alt, size: 50)
                            : null,
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
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          final newName = _displayNameController.text;
                          final newPhoneNumber = _phoneNumberController.text;
                          await _updateProfile(newName, newPhoneNumber);
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
