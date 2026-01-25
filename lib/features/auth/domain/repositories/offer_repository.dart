import '../entities/service_request_offer_entity.dart';

abstract class OfferRepository {
  Future<void> createOffer(Offer offer);
  Future<void> acceptOffer(String requestId, String offerId);
  Future<List<Offer>> getOffersByRequest(String requestId);
}
