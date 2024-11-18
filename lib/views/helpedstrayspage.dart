import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/adoptionpost_model.dart';
import '../components/adoption_post.dart';

class HelpedStraysPage extends StatelessWidget {
  const HelpedStraysPage({super.key});

  Future<List<AdoptionPost>> _fetchHelpedStrays() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('adoptions')
        .where('helpedBy', arrayContains: user.uid)
        .get();

    return querySnapshot.docs
        .map((doc) => AdoptionPost.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: const Text(
          'Helped Strays',
          style: TextStyle(
            color: Color(0xFF6C63FF), 
            fontWeight: FontWeight.bold, 
          ),
        ),
        backgroundColor: Colors.white, 
        iconTheme: const IconThemeData(color: Color(0xFF6C63FF)), 
      ),
      body: FutureBuilder<List<AdoptionPost>>(
        future: _fetchHelpedStrays(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No helped strays found'));
          }
          final helpedStrays = snapshot.data!;
          return ListView.builder(
            itemCount: helpedStrays.length,
            itemBuilder: (context, index) {
              return AdoptionPostWidget(post: helpedStrays[index]);
            },
          );
        },
      ),
    );
  }
}