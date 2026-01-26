import 'package:equatable/equatable.dart';

/// 💰 Entidad de dominio para negociación de precios
class PriceNegotiationEntity extends Equatable {
  final String id;             // ID del documento en Firestore
  final String requestId;      // ID de la solicitud original
  final String senderId;       // Usuario que envía la oferta (técnico o cliente)
  final String senderName;
  final String recipientId;    // Usuario que recibe la oferta
  final String recipientName;
  final double proposedPrice;  // Precio propuesto en esta oferta
  final double? originalPrice; // Precio original de la solicitud, si existe
  final String reason;         // Motivo de la oferta
  final String status;         // pending, accepted, rejected, expired
  final DateTime createdAt;    // Fecha de creación
  final DateTime? respondedAt; // Fecha de respuesta
  final String? responseReason; // Motivo de aceptación/rechazo

  const PriceNegotiationEntity({
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
