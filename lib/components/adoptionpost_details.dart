import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/adoptionpost_model.dart';
import '../views/helpform_page.dart';
import 'package:latlong2/latlong.dart';
import '../views/map_route_screen.dart'; // Import the new map screen
import 'package:geocoding/geocoding.dart'; // Import geocoding package
import 'package:url_launcher/url_launcher.dart';
import '../models/comment_model.dart';

class AdoptionDetailPage extends StatefulWidget {
  final AdoptionPost post;

  const AdoptionDetailPage({required this.post, super.key});

  @override
  _AdoptionDetailPageState createState() => _AdoptionDetailPageState();
}

class _AdoptionDetailPageState extends State<AdoptionDetailPage> {
  bool _isFlagged = false;
  bool _isHelped = false;
  String _fullAddress = 'Getting location...';
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _isFlagged = widget.post.flaggedBy.contains(user?.uid);
    _isHelped = widget.post.helpedBy.contains(user?.uid);
    _getFullAddress();
  }

  Future<void> _getFullAddress() async {
    try {
      final placemarks = await placemarkFromCoordinates(widget.post.latitude, widget.post.longitude);
      final placemark = placemarks.first;
      setState(() {
        _fullAddress = _formatAddress(placemark);
      });
    } catch (e) {
      setState(() {
        _fullAddress = 'Failed to get location';
      });
    }
  }

  String _formatAddress(Placemark placemark) {
    return [
      if (placemark.street != null && placemark.street!.isNotEmpty) placemark.street,
      if (placemark.locality != null && placemark.locality!.isNotEmpty) placemark.locality,
      if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) placemark.administrativeArea,
      if (placemark.country != null && placemark.country!.isNotEmpty) placemark.country,
    ].where((part) => part != null && part.isNotEmpty).join(', ');
  }

  void _toggleFlag() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      if (_isFlagged) {
        widget.post.flaggedBy.remove(user.uid);
      } else {
        widget.post.flaggedBy.add(user.uid);
      }
      _isFlagged = !_isFlagged;
    });

    await FirebaseFirestore.instance
        .collection('adoptions')
        .doc(widget.post.id)
        .update({
      'flaggedBy': widget.post.flaggedBy,
    });
  }

  Future<void> _toggleHelp() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HelpFormPage(postId: widget.post.id),
      ),
    );

    if (result == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() {
        if (_isHelped) {
          widget.post.helpedBy.remove(user.uid);
        } else {
          widget.post.helpedBy.add(user.uid);
        }
        _isHelped = !_isHelped;
      });

      await FirebaseFirestore.instance
          .collection('adoptions')
          .doc(widget.post.id)
          .update({
        'helpedBy': widget.post.helpedBy,
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  void _navigateToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapRouteScreen(
          reportLocation: LatLng(widget.post.latitude, widget.post.longitude),
        ),
      ),
    );
  }

  Future<void> _addComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _commentController.text.isEmpty) return;

    final comment = Comment(
      userId: user.uid,
      userName: user.displayName ?? 'Anonymous',
      text: _commentController.text,
      timestamp: DateTime.now(),
    );

    setState(() {
      widget.post.comments.add(comment.toMap());
    });

    await FirebaseFirestore.instance
        .collection('adoptions')
        .doc(widget.post.id)
        .update({
      'comments': widget.post.comments,
    });

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Column(
                  children: [
                    Image.network(
                      widget.post.animalImageUrl!,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                    if (widget.post.locationImageUrl != null)
                      Image.network(
                        widget.post.locationImageUrl!,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                  ],
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: Icon(
                      widget.post.flaggedBy.contains(user?.uid)
                          ? Icons.flag
                          : Icons.outlined_flag,
                      color: widget.post.flaggedBy.contains(user?.uid)
                          ? Colors.red
                          : Colors.white,
                      size: 30,
                    ),
                    onPressed: _toggleFlag,
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 70,
                  child: IconButton(
                    icon: Icon(
                      widget.post.helpedBy.contains(user?.uid)
                          ? Icons.volunteer_activism
                          : Icons.volunteer_activism_outlined,
                      color: widget.post.helpedBy.contains(user?.uid)
                          ? Colors.green
                          : Colors.white,
                      size: 30,
                    ),
                    onPressed: _toggleHelp,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.description,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(_fullAddress, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _navigateToMap,
                    child: const Text(
                      'Check Location on Map',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 131, // Adjusted height to prevent overflow
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildInfoCard('Species', widget.post.species),
                        _buildInfoCard('Size', widget.post.size),
                        _buildInfoCard('Injured', widget.post.injured ? 'Yes' : 'No', icon: widget.post.injured ? Icons.check : Icons.close),
                        _buildInfoCard('Needs Immediate Attention', widget.post.needsImmediateAttention ? 'Yes' : 'No', icon: widget.post.needsImmediateAttention ? Icons.check : Icons.close),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.post.reporterId)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return const Text("Error loading user details.");
                      }
                      var userData = snapshot.data!.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(userData['photoURL'] ?? ''),
                          radius: 30,
                        ),
                        title: Text(
                          userData['displayName'] ?? 'No name provided', // Display the user's display name
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.post.reporterEmail),
                            if (userData['phoneNumber'] != null)
                              Row(
                                children: [
                                  const Icon(Icons.phone, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(userData['phoneNumber']),
                                  const SizedBox(width: 8), // Added space to push the button to the right
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      minimumSize: const Size(50, 30),
                                    ),
                                    onPressed: () => _makePhoneCall(userData['phoneNumber']),
                                    child: const Text(
                                      'Call',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _toggleFlag,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFlagged ? Colors.green : const Color(0xFF6C63FF),
                              minimumSize: const Size(150, 50), // Adjusted size
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isFlagged ? 'Seen' : 'Flag as Seen',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _toggleHelp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isHelped ? Colors.green : Colors.grey,
                              minimumSize: const Size(150, 50), // Adjusted size
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isHelped ? 'Helped' : 'Help',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Comment section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comments',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.post.comments.length,
                          itemBuilder: (context, index) {
                            final comment = Comment.fromMap(widget.post.comments[index]);
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(comment.userName),
                                      radius: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            comment.userName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comment.text,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                            maxLines: null, // Allow text to wrap
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comment.timestamp.toIso8601String(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  labelText: 'Add a comment',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addComment,
                              child: const Text(
                                'Comment',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildInfoCard(String title, String value, {IconData? icon}) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, color: Colors.green, size: 24),
          const SizedBox(height: 4),
          Center(
            child: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}