import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionItem {
  final String medicine;
  final String dosage;

  const PrescriptionItem({required this.medicine, required this.dosage});

  factory PrescriptionItem.fromMap(Map<String, dynamic> data) {
    return PrescriptionItem(
      medicine: data['medicine'] as String? ?? '',
      dosage: data['dosage'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'medicine': medicine, 'dosage': dosage};
}

class TreatmentModel {
  final String id;
  final String animalTagId;
  final String vetId;
  final String vetName;
  final String farmerId;
  final String urgency; // 'Routine' | 'Urgent' | 'Surgery'
  final String notes;
  final String status; // 'Pending Approval' | 'Approved' | 'Rejected'
  final String adminComments;
  final List<PrescriptionItem> prescription;
  final DateTime? date;
  final DateTime? nextDueDate;
  final bool deletionRequest;
  final String deletionReason;

  const TreatmentModel({
    this.id = '',
    required this.animalTagId,
    this.vetId = '',
    this.vetName = '',
    this.farmerId = '',
    this.urgency = 'Routine',
    this.notes = '',
    this.status = 'Pending Approval',
    this.adminComments = '',
    this.prescription = const [],
    this.date,
    this.nextDueDate,
    this.deletionRequest = false,
    this.deletionReason = '',
  });

  factory TreatmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TreatmentModel(
      id: doc.id,
      animalTagId: data['animalTagId'] as String? ?? '',
      vetId: data['vetId'] as String? ?? '',
      vetName: data['vetName'] as String? ?? '',
      farmerId: data['farmerId'] as String? ?? '',
      urgency: data['urgency'] as String? ?? 'Routine',
      notes: data['notes'] as String? ?? '',
      status: data['status'] as String? ?? 'Pending Approval',
      adminComments: data['adminComments'] as String? ?? '',
      prescription: ((data['prescription'] as List<dynamic>?) ?? [])
          .map((p) => PrescriptionItem.fromMap(p as Map<String, dynamic>))
          .toList(),
      date: (data['date'] as Timestamp?)?.toDate(),
      nextDueDate: data['nextDueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['nextDueDate'] as int)
          : null,
      deletionRequest: data['deletionRequest'] as bool? ?? false,
      deletionReason: data['deletionReason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'animalTagId': animalTagId,
      'vetId': vetId,
      'vetName': vetName,
      'farmerId': farmerId,
      'urgency': urgency,
      'notes': notes,
      'status': status,
      'adminComments': adminComments,
      'prescription': prescription.map((p) => p.toMap()).toList(),
      'date': FieldValue.serverTimestamp(),
      'nextDueDate': nextDueDate?.millisecondsSinceEpoch,
      'deletionRequest': deletionRequest,
      'deletionReason': deletionReason,
    };
  }
}
