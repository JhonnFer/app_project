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
}

/// Entidad principal de solicitud de servicio
class ServiceRequestEntity extends Equatable {
  final String id;
  final String clientEmail;
  final String description;
  final double proposedPrice;
  final RequestStatus status;

  const ServiceRequestEntity({
    required this.id,
    required this.clientEmail,
    required this.description,
    required this.proposedPrice,
    required this.status,
  });

  @override
  List<Object?> get props =>
      [id, clientEmail, description, proposedPrice, status];
}

/// Oferta de un técnico o cliente
class Offer extends Equatable {
  final String id;
  final String requestId;
  final String senderName;
  final double proposedPrice;
  final OfferStatus status;

  const Offer({
    required this.id,
    required this.requestId,
    required this.senderName,
    required this.proposedPrice,
    required this.status,
  });

  @override
  List<Object?> get props =>
      [id, requestId, senderName, proposedPrice, status];
}
