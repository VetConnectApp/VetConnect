import 'package:cloud_firestore/cloud_firestore.dart';

class AnimalModel {
  final String tagId;
  final String nfcId;
  final String barcodeId;
  final String species;
  final String breed;
  final String farmerId;
  final DateTime? createdAt;

  const AnimalModel({
    required this.tagId,
    this.nfcId = '',
    this.barcodeId = '',
    this.species = 'Cow',
    this.breed = '',
    this.farmerId = '',
    this.createdAt,
  });

  factory AnimalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AnimalModel(
      tagId: data['tagId'] as String? ?? doc.id,
      nfcId: data['nfcId'] as String? ?? '',
      barcodeId: data['barcodeId'] as String? ?? '',
      species: data['species'] as String? ?? 'Cow',
      breed: data['breed'] as String? ?? '',
      farmerId: data['farmerId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory AnimalModel.fromMap(Map<String, dynamic> data) {
    return AnimalModel(
      tagId: data['tagId'] as String? ?? '',
      nfcId: data['nfcId'] as String? ?? '',
      barcodeId: data['barcodeId'] as String? ?? '',
      species: data['species'] as String? ?? 'Cow',
      breed: data['breed'] as String? ?? '',
      farmerId: data['farmerId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tagId': tagId,
      'nfcId': nfcId,
      'barcodeId': barcodeId,
      'species': species,
      'breed': breed,
      'farmerId': farmerId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
