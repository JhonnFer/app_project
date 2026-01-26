import '../repositories/price_negotiation_repository.dart';

class RespondToNegotiationUseCase {
  final PriceNegotiationRepository repository;

  RespondToNegotiationUseCase(this.repository);

  Future<void> accept({
    required String negotiationId,
    required String userId,
    required double agreedPrice,
  }) {
    return repository.acceptNegotiation(
      negotiationId: negotiationId,
      userId: userId,
      agreedPrice: agreedPrice,
    );
  }

  Future<void> reject({
    required String negotiationId,
    required String userId,
    required String reason,
  }) {
    return repository.rejectNegotiation(
      negotiationId: negotiationId,
      userId: userId,
      reason: reason,
    );
  }
}
