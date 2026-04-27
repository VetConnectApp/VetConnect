import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/animal_model.dart';
import '../models/treatment_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── User ───────────────────────────────────────────────────────────────

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) return UserModel.fromFirestore(doc);
    } catch (e) {
      // ignore and return null
    }
    return null;
  }

  Future<void> updateUserProfile(
      String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  /// Alias used by profile_view — partial field update.
  Future<void> updateUserFields(
      String uid, Map<String, dynamic> fields) async {
    await _db.collection('users').doc(uid).update(fields);
  }

  // ─── Animals ─────────────────────────────────────────────────────────────

  Future<AnimalModel?> getAnimalByTag(String tagId) async {
    final q = await _db
        .collection('animals')
        .where('tagId', isEqualTo: tagId)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) return AnimalModel.fromFirestore(q.docs.first);
    return null;
  }

  Future<AnimalModel?> getAnimalByNfc(String nfcId) async {
    final q = await _db
        .collection('animals')
        .where('nfcId', isEqualTo: nfcId)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) return AnimalModel.fromFirestore(q.docs.first);
    return null;
  }

  Future<AnimalModel?> getAnimalByBarcode(String barcodeId) async {
    final q = await _db
        .collection('animals')
        .where('barcodeId', isEqualTo: barcodeId)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) return AnimalModel.fromFirestore(q.docs.first);
    return null;
  }

  /// Smart lookup: tries tagId → nfcId → barcodeId
  Future<AnimalModel?> findAnimal(String scannedId) async {
    return await getAnimalByTag(scannedId) ??
        await getAnimalByNfc(scannedId) ??
        await getAnimalByBarcode(scannedId);
  }

  Future<void> registerAnimal(AnimalModel animal) async {
    await _db
        .collection('animals')
        .doc(animal.tagId)
        .set(animal.toMap());
  }

  Stream<List<AnimalModel>> getFarmerAnimals(String farmerId) {
    return _db
        .collection('animals')
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AnimalModel.fromFirestore(d)).toList());
  }

  Future<int> countAnimals() async {
    final snap = await _db.collection('animals').count().get();
    return snap.count ?? 0;
  }

  Future<int> countFarmerAnimals(String farmerId) async {
    final snap = await _db
        .collection('animals')
        .where('farmerId', isEqualTo: farmerId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  // ─── Treatments ──────────────────────────────────────────────────────────

  Future<void> addTreatment(TreatmentModel treatment) async {
    await _db.collection('treatments').add(treatment.toMap());
  }

  Stream<List<TreatmentModel>> getVetTreatments(String vetId) {
    return _db
        .collection('treatments')
        .where('vetId', isEqualTo: vetId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => TreatmentModel.fromFirestore(d)).toList());
  }

  Stream<List<TreatmentModel>> getFarmerTreatments(String farmerId) {
    return _db
        .collection('treatments')
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => TreatmentModel.fromFirestore(d)).toList());
  }

  Stream<List<TreatmentModel>> getAnimalTreatments(String animalTagId) {
    return _db
        .collection('treatments')
        .where('animalTagId', isEqualTo: animalTagId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => TreatmentModel.fromFirestore(d)).toList());
  }

  Stream<List<TreatmentModel>> getAllTreatments({String? status}) {
    Query<Map<String, dynamic>> q = _db.collection('treatments');
    if (status != null) q = q.where('status', isEqualTo: status);
    return q
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => TreatmentModel.fromFirestore(d)).toList());
  }

  Future<void> updateTreatmentStatus(
      String id, String status, String comment) async {
    await _db.collection('treatments').doc(id).update({
      'status': status,
      'adminComments': comment,
    });
  }

  Future<void> requestTreatmentDeletion(String id, String reason) async {
    await _db.collection('treatments').doc(id).update({
      'deletionRequest': true,
      'deletionReason': reason,
    });
  }

  Future<void> deleteTreatment(String id) async {
    await _db.collection('treatments').doc(id).delete();
  }

  Future<int> countVetTreatments(String vetId) async {
    final snap = await _db
        .collection('treatments')
        .where('vetId', isEqualTo: vetId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<int> countPendingTreatments() async {
    final snap = await _db
        .collection('treatments')
        .where('status', isEqualTo: 'Pending Approval')
        .count()
        .get();
    return snap.count ?? 0;
  }

  // ─── Emergencies ─────────────────────────────────────────────────────────

  Future<void> addEmergency({
    required String farmerId,
    required String note,
    String photoUrl = '',
    String voiceMemoUrl = '',
  }) async {
    await _db.collection('emergencies').add({
      'farmerId': farmerId,
      'note': note,
      'photoUrl': photoUrl,
      'voiceMemoUrl': voiceMemoUrl,
      'status': 'Open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
