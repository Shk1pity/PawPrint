import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/adoption_post.dart';
import '../models/adoptionpost_model.dart';

class AdoptionsScreen extends StatefulWidget {
  const AdoptionsScreen({super.key});

  @override
  _AdoptionsScreenState createState() => _AdoptionsScreenState();
}

class _AdoptionsScreenState extends State<AdoptionsScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF6C63FF)),
        titleTextStyle: const TextStyle(color: Color(0xFF6C63FF), fontSize: 20, fontWeight: FontWeight.bold),
        title: Row(
          children: [
            const Text('Stray Reports', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('adoptions').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No adoptions available.'));
            }
            final filteredDocs = snapshot.data!.docs.where((doc) {
              final post = AdoptionPost.fromMap(doc.data() as Map<String, dynamic>);
              return post.description.toLowerCase().contains(searchQuery);
            }).toList();
            return ListView(
              children: filteredDocs.map((doc) {
                final post = AdoptionPost.fromMap(doc.data() as Map<String, dynamic>);
                return AdoptionPostWidget(post: post);
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
