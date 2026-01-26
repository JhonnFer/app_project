// lib/features/auth/data/datasources/price_negotiation_remote_datasource_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/price_negotiation_entity.dart';
import 'price_negotiation_remote_datasource.dart';

class PriceNegotiationRemoteDatasourceImpl
    implements PriceNegotiationRemoteDatasource {
  final FirebaseFirestore firestore;

  PriceNegotiationRemoteDatasourceImpl({
    required this.firestore,
  });

  @override
  Stream<List<PriceNegotiationEntity>> getPendingNegotiations(
    String recipientId,
  ) {
    return firestore
        .collection('price_negotiations')
        .where('recipientId', isEqualTo: recipientId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return PriceNegotiationEntity(
              id: doc.id,
              requestId: data['requestId'],
              senderId: data['senderId'],
              senderName: data['senderName'],
              recipientId: data['recipientId'],
              recipientName: data['recipientName'],
              proposedPrice: (data['proposedPrice'] as num).toDouble(),
              originalPrice:
                  (data['originalPrice'] as num?)?.toDouble(),
              reason: data['reason'],
              status: data['status'],
              createdAt: (data['createdAt'] as Timestamp).toDate(),
              respondedAt: data['respondedAt'] != null
                  ? (data['respondedAt'] as Timestamp).toDate()
                  : null,
              responseReason: data['responseReason'],
            );
          }).toList(),
        );
  }

  @override
  Future<void> acceptNegotiation({
    required String negotiationId,
    required String userId,
    required double agreedPrice,
  }) async {
    await firestore
        .collection('price_negotiations')
        .doc(negotiationId)
        .update({
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
      'agreedPrice': agreedPrice,
    });
  }

  @override
  Future<void> rejectNegotiation({
    required String negotiationId,
    required String userId,
    required String reason,
  }) async {
    await firestore
        .collection('price_negotiations')
        .doc(negotiationId)
        .update({
      'status': 'rejected',
      'respondedAt': FieldValue.serverTimestamp(),
      'responseReason': reason,
    });
  }
}
