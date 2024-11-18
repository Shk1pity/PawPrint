import 'package:flutter/material.dart';

class InterestedUserTile extends StatelessWidget {
  final String photoURL;
  final String displayName;
  final String email;
  final String postTitle;
  final String postId;
  final String userId;
  final String? confirmedAdopter;
  final VoidCallback onConfirm;

  const InterestedUserTile({
    required this.photoURL,
    required this.displayName,
    required this.email,
    required this.postTitle,
    required this.postId,
    required this.userId,
    this.confirmedAdopter,
    required this.onConfirm,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(photoURL),
        radius: 30,
      ),
      title: Text(displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(email),
          Text('Interested in: $postTitle', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (confirmedAdopter == userId)
            const Text('Confirmed Adopter', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
      trailing: confirmedAdopter == null
          ? ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            )
          : confirmedAdopter == userId
              ? const Icon(Icons.check, color: Colors.green)
              : null,
    );
  }
}