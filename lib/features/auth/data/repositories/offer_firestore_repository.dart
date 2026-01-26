import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/service_request_offer_entity.dart';
import '../../domain/repositories/offer_repository.dart';

class OfferFirestoreRepository implements OfferRepository {
  final FirebaseFirestore firestore;

  OfferFirestoreRepository({required this.firestore});

  @override
  Future<void> createOffer(Offer offer) async {
    final docRef = firestore.collection('offers').doc(offer.id);
    await docRef.set({
      'requestId': offer.requestId,
      'senderName': offer.senderName,
      'proposedPrice': offer.proposedPrice,
      'status': offer.status.name,
    });
  }

  @override
  Future<List<Offer>> getOffersByRequest(String requestId) async {
    final querySnapshot = await firestore
        .collection('offers')
        .where('requestId', isEqualTo: requestId)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return Offer(
        id: doc.id,
        requestId: data['requestId'],
        senderName: data['senderName'],
        proposedPrice: (data['proposedPrice'] as num).toDouble(),
        status: OfferStatus.values.firstWhere(
            (e) => e.name == (data['status'] as String),
            orElse: () => OfferStatus.pending),
      );
    }).toList();
  }

  @override
  Future<void> acceptOffer(String requestId, String offerId) async {
    final batch = firestore.batch();

    // Obtener todas las ofertas de la solicitud
    final offersQuery = await firestore
        .collection('offers')
        .where('requestId', isEqualTo: requestId)
        .get();

    for (var doc in offersQuery.docs) {
      final docRef = firestore.collection('offers').doc(doc.id);
      if (doc.id == offerId) {
        batch.update(docRef, {'status': OfferStatus.accepted.name});
      } else {
        batch.update(docRef, {'status': OfferStatus.rejected.name});
      }
    }

    // Actualizar la solicitud para marcarla como assigned
    final requestDocRef = firestore.collection('service_requests').doc(requestId);
    batch.update(requestDocRef, {'status': RequestStatus.assigned.name});

    await batch.commit();
  }
}
