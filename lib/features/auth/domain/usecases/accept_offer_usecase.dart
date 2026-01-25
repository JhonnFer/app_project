import '../entities/service_request_offer_entity.dart';
import '../repositories/offer_repository.dart';

class AcceptOfferUseCase {
  final OfferRepository repository;

  AcceptOfferUseCase(this.repository);

  Future<void> call(String requestId, String offerId) async {
    // Esto marcará la oferta como accepted y rechazará las demás
    await repository.acceptOffer(requestId, offerId);
  }
}
