import '../entities/price_negotiation_entity.dart';

abstract class PriceNegotiationRepository {
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
