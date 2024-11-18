class AdoptionPost {
  final String id;
  final String reporterId;
  final String description;
  final String location;
  final String reporterEmail;
  final String? animalImageUrl;
  final String? locationImageUrl;
  final String species;
  final String size;
  final bool injured;
  final bool needsImmediateAttention;
  final double latitude; // Add latitude
  final double longitude; // Add longitude
  int flags;
  List<String> flaggedBy;
  int helps;
  List<String> helpedBy;
  List<Map<String, dynamic>> comments;

  AdoptionPost({
    required this.id,
    required this.reporterId,
    required this.description,
    required this.location,
    required this.reporterEmail,
    this.animalImageUrl,
    this.locationImageUrl,
    required this.species,
    required this.size,
    required this.injured,
    required this.needsImmediateAttention,
    required this.latitude, // Add latitude
    required this.longitude, // Add longitude
    this.flags = 0,
    this.flaggedBy = const [],
    this.helps = 0,
    this.helpedBy = const [],
    this.comments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'description': description,
      'location': location,
      'reporterEmail': reporterEmail,
      'animalImageUrl': animalImageUrl,
      'locationImageUrl': locationImageUrl,
      'species': species,
      'size': size,
      'injured': injured,
      'needsImmediateAttention': needsImmediateAttention,
      'latitude': latitude, // Add latitude
      'longitude': longitude, // Add longitude
      'flags': flags,
      'flaggedBy': flaggedBy,
      'helps': helps,
      'helpedBy': helpedBy,
      'comments': comments,
    };
  }

  factory AdoptionPost.fromMap(Map<String, dynamic> map) {
    return AdoptionPost(
      id: map['id'] ?? '',
      reporterId: map['reporterId'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      reporterEmail: map['reporterEmail'] ?? '',
      animalImageUrl: map['animalImageUrl'],
      locationImageUrl: map['locationImageUrl'],
      species: map['species'] ?? '',
      size: map['size'] ?? '',
      injured: map['injured'] ?? false,
      needsImmediateAttention: map['needsImmediateAttention'] ?? false,
      latitude: map['latitude'] ?? 0.0, // Add latitude
      longitude: map['longitude'] ?? 0.0, // Add longitude
      flags: map['flags'] ?? 0,
      flaggedBy: List<String>.from(map['flaggedBy'] ?? []),
      helps: map['helps'] ?? 0,
      helpedBy: List<String>.from(map['helpedBy'] ?? []),
      comments: List<Map<String, dynamic>>.from(map['comments'] ?? []),
    );
  }
}
