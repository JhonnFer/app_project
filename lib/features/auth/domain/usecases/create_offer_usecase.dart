import '../entities/service_request_offer_entity.dart';
import '../repositories/offer_repository.dart';

class CreateOfferUseCase {
  final OfferRepository repository;

  CreateOfferUseCase(this.repository);

  Future<void> call(Offer offer) async {
    // Regla de negocio simple:
    // No permitir ofertas si la solicitud está asignada
    // Esta verificación podría hacerse en el repository si quieres
    await repository.createOffer(offer);
  }
}
