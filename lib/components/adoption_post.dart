import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/adoptionpost_model.dart';
import '../components/adoptionpost_details.dart'; // Import the details page

class AdoptionPostWidget extends StatefulWidget {
  final AdoptionPost post;
  final bool showDetailsButton;

  const AdoptionPostWidget({required this.post, this.showDetailsButton = true, super.key});

  @override
  _AdoptionPostWidgetState createState() => _AdoptionPostWidgetState();
}

class _AdoptionPostWidgetState extends State<AdoptionPostWidget> {
  bool _isFlagged = false;
  bool _isHelped = false;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _isFlagged = widget.post.flaggedBy.contains(user?.uid);
    _isHelped = widget.post.helpedBy.contains(user?.uid);
  }

  void _toggleFlag() async {
    if (user == null) return;

    setState(() {
      if (_isFlagged) {
        widget.post.flaggedBy.remove(user!.uid);
        widget.post.flags--;
      } else {
        widget.post.flaggedBy.add(user!.uid);
        widget.post.flags++;
      }
      _isFlagged = !_isFlagged;
    });

    await FirebaseFirestore.instance
        .collection('adoptions')
        .doc(widget.post.id)
        .update({
      'flaggedBy': widget.post.flaggedBy,
      'flags': widget.post.flags,
    });
  }

  void _toggleHelp() async {
    if (user == null) return;

    setState(() {
      if (_isHelped) {
        widget.post.helpedBy.remove(user!.uid);
        widget.post.helps--;
      } else {
        widget.post.helpedBy.add(user!.uid);
        widget.post.helps++;
      }
      _isHelped = !_isHelped;
    });

    await FirebaseFirestore.instance
        .collection('adoptions')
        .doc(widget.post.id)
        .update({
      'helpedBy': widget.post.helpedBy,
      'helps': widget.post.helps,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = user?.email == widget.post.reporterEmail;

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
            if (widget.post.animalImageUrl != null) // Display image if it exists
              Center(
                child: Container(
                  width: double.infinity, // Set the width to fill the available space
                  height: 200, // Set the desired height
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12), // Curve the edges
                    border: Border.all(
                      color: const Color(0xFF6C63FF), // Set the border color
                      width: 2, // Set the border width
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.post.animalImageUrl!,
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
            const SizedBox(height: 15), // Add some space between the image and the text
            Text(
              widget.post.description,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 10),
            Text('Reporter: ${widget.post.reporterEmail}'),
            Text('Species: ${widget.post.species}'),
            Text('Size: ${widget.post.size}'),
            if (widget.post.injured) Text('Injured: Yes', style: TextStyle(color: Colors.red)),
            if (widget.post.needsImmediateAttention) Text('Needs Immediate Attention: Yes', style: TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isFlagged ? Icons.visibility : Icons.visibility_off,
                    color: _isFlagged ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleFlag,
                ),
                Text('${widget.post.flags}'),
                const SizedBox(width: 10), // Add some space between the flag button and the other buttons
                IconButton(
                  icon: Icon(
                    _isHelped ? Icons.volunteer_activism : Icons.volunteer_activism_outlined,
                    color: _isHelped ? Colors.green : Colors.grey,
                  ),
                  onPressed: _toggleHelp,
                ),
                Text('${widget.post.helps}'),
                const SizedBox(width: 10), // Add some space between the help button and the other buttons
                if (widget.showDetailsButton && !isOwner)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdoptionDetailPage(post: widget.post),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                if (user != null && isOwner)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _deletePost(context, widget.post.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(100, 36), // Smaller size for the delete button
                      ),
                      child: const Text(
                        'Delete Post',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePost(BuildContext context, String postId) async {
    try {
      await FirebaseFirestore.instance.collection('adoptions').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting post')),
      );
    }
  }
}
