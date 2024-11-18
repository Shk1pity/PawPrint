import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/adoptionpost_model.dart';
import '../components/adoption_post.dart';

class UserAdoptionsPage extends StatelessWidget {
  const UserAdoptionsPage({super.key});

  Future<List<AdoptionPost>> _fetchUserAdoptions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('adoptions')
        .where('reporterEmail', isEqualTo: user.email)
        .get();

    return querySnapshot.docs
        .map((doc) => AdoptionPost.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      appBar: AppBar(
        title: const Text(
          'Reported Strays',
          style: TextStyle(
            color: Color(0xFF6C63FF), // Set title text color
            fontWeight: FontWeight.bold, // Make title text bold
          ),
        ),
        backgroundColor: Colors.white, // Set AppBar background color to white
        iconTheme: const IconThemeData(color: Color(0xFF6C63FF)), // Set AppBar icon color
      ),
      body: FutureBuilder<List<AdoptionPost>>(
        future: _fetchUserAdoptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No adoptions found'));
          }
          final adoptions = snapshot.data!;
          return ListView.builder(
            itemCount: adoptions.length,
            itemBuilder: (context, index) {
              return AdoptionPostWidget(post: adoptions[index], showDetailsButton: false);
            },
          );
        },
      ),
    );
  }
}
