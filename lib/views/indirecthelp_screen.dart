import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/helpreport_model.dart';

class IndirectHelpPage extends StatelessWidget {
  const IndirectHelpPage({Key? key}) : super(key: key);

  Future<List<HelpReport>> _fetchHelpReports() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userPostsSnapshot = await FirebaseFirestore.instance
        .collection('adoptions')
        .where('reporterId', isEqualTo: user.uid)
        .get();

    final postIds = userPostsSnapshot.docs.map((doc) => doc.id).toList();

    final helpReportsSnapshot = await FirebaseFirestore.instance
        .collection('help_reports')
        .where('postId', whereIn: postIds)
        .get();

    return helpReportsSnapshot.docs
        .map((doc) => HelpReport.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Indirect Help'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF6C63FF)),
        titleTextStyle: const TextStyle(color: Color(0xFF6C63FF), fontSize: 20, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<HelpReport>>(
        future: _fetchHelpReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading help reports.'));
          }
          final helpReports = snapshot.data ?? [];
          if (helpReports.isEmpty) {
            return const Center(child: Text('No help reports found.'));
          }
          return ListView.builder(
            itemCount: helpReports.length,
            itemBuilder: (context, index) {
              final helpReport = helpReports[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (helpReport.imageUrl.isNotEmpty)
                        Center(
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF6C63FF),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                helpReport.imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  } else {
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                            : null,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 15),
                      Text(
                        helpReport.description,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Reported on: ${helpReport.timestamp.toLocal()}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}