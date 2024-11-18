import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import '../models/adoptionpost_model.dart';
import 'adoptions_screen.dart';

class PostAdoptionScreen extends StatefulWidget {
  const PostAdoptionScreen({super.key});

  @override
  _PostAdoptionScreenState createState() => _PostAdoptionScreenState();
}

class _PostAdoptionScreenState extends State<PostAdoptionScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  String _species = 'Cat';
  String _size = 'Small';
  bool _injured = false;
  bool _needsImmediateAttention = false;
  File? _animalImage;
  File? _locationImage;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  LatLng? _currentPosition;
  String _currentAddress = 'Getting location...';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    final placemark = placemarks.first;

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _currentAddress = '${placemark.locality}, ${placemark.country}';
    });
  }

  Future<void> _pickImage(ImageSource source, bool isAnimalImage) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        if (isAnimalImage) {
          _animalImage = File(pickedFile.path);
        } else {
          _locationImage = File(pickedFile.path);
        }
      });
    }
  }

  void _showImagePickerOptions(bool isAnimalImage) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery, isAnimalImage);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera, isAnimalImage);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _postAdoption() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to post an adoption.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String? animalImageUrl;
      String? locationImageUrl;
      if (_animalImage != null) {
        final storageRef = FirebaseStorage.instance.ref().child('adoption_images').child(user.uid).child('animal_${DateTime.now().toIso8601String()}');
        await storageRef.putFile(_animalImage!);
        animalImageUrl = await storageRef.getDownloadURL();
      }
      if (_locationImage != null) {
        final storageRef = FirebaseStorage.instance.ref().child('adoption_images').child(user.uid).child('location_${DateTime.now().toIso8601String()}');
        await storageRef.putFile(_locationImage!);
        locationImageUrl = await storageRef.getDownloadURL();
      }

      final postId = FirebaseFirestore.instance.collection('adoptions').doc().id; // Generate a unique ID
      final post = AdoptionPost(
        id: postId,
        reporterId: user.uid,
        description: _descriptionController.text,
        location: _currentAddress,
        reporterEmail: user.email ?? 'No email',
        animalImageUrl: animalImageUrl,
        locationImageUrl: locationImageUrl,
        species: _species,
        size: _size,
        injured: _injured,
        needsImmediateAttention: _needsImmediateAttention,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        flags: 0,
        flaggedBy: [],
      );

      try {
        await FirebaseFirestore.instance.collection('adoptions').doc(postId).set(post.toMap());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adoption posted successfully!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdoptionsScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post adoption: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Adoption'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF6C63FF)),
        titleTextStyle: const TextStyle(color: Color(0xFF6C63FF), fontSize: 20, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showImagePickerOptions(true),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: _animalImage != null
                                  ? FileImage(_animalImage!)
                                  : const AssetImage('assets/default_profile.png') as ImageProvider,
                              child: _animalImage == null
                                  ? const Icon(Icons.camera_alt, size: 50)
                                  : null,
                            ),
                            Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                              child: const Text(
                                'Animal Image',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => _showImagePickerOptions(false),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: _locationImage != null
                                  ? FileImage(_locationImage!)
                                  : const AssetImage('assets/default_profile.png') as ImageProvider,
                              child: _locationImage == null
                                  ? const Icon(Icons.camera_alt, size: 50)
                                  : null,
                            ),
                            Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                              child: const Text(
                                'Location Image',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Description cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField(
                        value: _species,
                        onChanged: (value) {
                          setState(() {
                            _species = value as String;
                          });
                        },
                        items: const [
                          DropdownMenuItem(
                            child: Text('Cat'),
                            value: 'Cat',
                          ),
                          DropdownMenuItem(
                            child: Text('Dog'),
                            value: 'Dog',
                          ),
                          DropdownMenuItem(
                            child: Text('Bird'),
                            value: 'Bird',
                          ),
                          DropdownMenuItem(
                            child: Text('Other'),
                            value: 'Other',
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Species',
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField(
                        value: _size,
                        onChanged: (value) {
                          setState(() {
                            _size = value as String;
                          });
                        },
                        items: const [
                          DropdownMenuItem(
                            child: Text('Small'),
                            value: 'Small',
                          ),
                          DropdownMenuItem(
                            child: Text('Medium'),
                            value: 'Medium',
                          ),
                          DropdownMenuItem(
                            child: Text('Large'),
                            value: 'Large',
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Size',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Text('Injured: '),
                          Checkbox(
                            value: _injured,
                            onChanged: (value) {
                              setState(() {
                                _injured = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Text('Needs Immediate Attention: '),
                          Checkbox(
                            value: _needsImmediateAttention,
                            onChanged: (value) {
                              setState(() {
                                _needsImmediateAttention = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _postAdoption,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Post Adoption', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          backgroundColor: Colors.white,
        );
      }
    }
  
