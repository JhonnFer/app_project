import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/price_negotiation_entity.dart';
abstract class PriceNegotiationRemoteDatasource {
  Stream<List<PriceNegotiationEntity>> getPendingNegotiations(
    String recipientId,
  );

  Future<void> acceptNegotiation({
    required String negotiationId,
    required String userId,
    required double agreedPrice,
  });

  Future<void> rejectNegotiation({
    required String negotiationId,
    required String userId,
    required String reason,
  });
}
