import '../../domain/entities/price_negotiation_entity.dart';
import '../../domain/repositories/price_negotiation_repository.dart';
import '../datasources/price_negotiation_remote_datasource.dart';

class PriceNegotiationRepositoryImpl
    implements PriceNegotiationRepository {
  final PriceNegotiationRemoteDatasource remote;

  PriceNegotiationRepositoryImpl(this.remote);

  @override
  Stream<List<PriceNegotiationEntity>> getPendingNegotiations(
      String recipientId) {
    return remote.getPendingNegotiations(recipientId);
  }

  @override
  Future<void> acceptNegotiation({
    required String negotiationId,
    required String userId,
    required double agreedPrice,
  }) {
    return remote.acceptNegotiation(
      negotiationId: negotiationId,
      userId: userId,
      agreedPrice: agreedPrice,
    );
  }

  @override
  Future<void> rejectNegotiation({
    required String negotiationId,
    required String userId,
    required String reason,
  }) {
    return remote.rejectNegotiation(
      negotiationId: negotiationId,
      userId: userId,
      reason: reason,
    );
  }
}
