class HelpReport {
  final String id;
  final String userId;
  final String postId;
  final String description;
  final String imageUrl;
  final DateTime timestamp;

  HelpReport({
    required this.id,
    required this.userId,
    required this.postId,
    required this.description,
    required this.imageUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'postId': postId,
      'description': description,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HelpReport.fromFirestore(Map<String, dynamic> data, String id) {
    return HelpReport(
      id: id,
      userId: data['userId'],
      postId: data['postId'],
      description: data['description'],
      imageUrl: data['imageUrl'],
      timestamp: DateTime.parse(data['timestamp']),
    );
  }
}