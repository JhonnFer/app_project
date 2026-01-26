import '../entities/price_negotiation_entity.dart';
import '../repositories/price_negotiation_repository.dart';

class GetPendingNegotiationsUseCase {
  final PriceNegotiationRepository repository;

  GetPendingNegotiationsUseCase(this.repository);

  Stream<List<PriceNegotiationEntity>> call(String recipientId) {
    return repository.getPendingNegotiations(recipientId);
  }
}