import 'package:equatable/equatable.dart';

/// Estados de la solicitud de servicio
enum RequestStatus {
  open,        // Abierta, esperando ofertas
  negotiated,  // En negociación
  assigned,    // Oferta aceptada
  cancelled,   // Cancelada
}

/// Estados de una oferta/negociación
enum OfferStatus {
  pending,   // Esperando decisión del cliente
  accepted,  // Aceptada por el cliente
  rejected,  // Rechazada
  expired,   // Caducada (opcional)
}

/// Entidad principal de solicitud de servicio
class ServiceRequestEntity extends Equatable {
  final String id;
  final String clientId;
  final String description;
  final double proposedPrice;
  final RequestStatus status;
  final List<Offer> offers; // Lista de ofertas/negociaciones

  const ServiceRequestEntity({
    required this.id,
    required this.clientId,
    required this.description,
    required this.proposedPrice,
    required this.status,
    this.offers = const [],
  });

  @override
  List<Object?> get props =>
      [id, clientId, description, proposedPrice, status, offers];
}

/// Oferta o contraoferta de un técnico o cliente
class Offer extends Equatable {
  final String id;
  final String requestId;
  final String senderId;       // Quién hace la oferta (técnico o cliente)
  final String senderName;
  final String recipientId;    // Quién recibe la oferta
  final String recipientName;
  final double proposedPrice;  // Precio de esta oferta/contraoferta
  final double? originalPrice; // Precio original de la solicitud
  final String reason;         // Motivo de la contraoferta
  final OfferStatus status;
  final DateTime createdAt;    // Fecha de creación
  final DateTime? respondedAt; // Fecha de respuesta
  final String? responseReason;// Motivo de aceptación/rechazo

  const Offer({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.recipientName,
    required this.proposedPrice,
    this.originalPrice,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.responseReason,
  });

  /// Devuelve true si esta oferta es una contraoferta
  bool isCounterOffer() {
    if (originalPrice == null) return false;
    return proposedPrice != originalPrice;
  }

  @override
  List<Object?> get props => [
        id,
        requestId,
        senderId,
        senderName,
        recipientId,
        recipientName,
        proposedPrice,
        originalPrice,
        reason,
        status,
        createdAt,
        respondedAt,
        responseReason,
      ];
}
