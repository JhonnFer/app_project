import 'package:equatable/equatable.dart';

/// 💰 Entidad de dominio para negociación de precios
class PriceNegotiationEntity extends Equatable {
  final String id;
  final String requestId;
  final String
      senderId; // Usuario que envía la contraoferta (técnico o cliente)
  final String senderName;
  final String recipientId; // Usuario que recibe la contraoferta
  final String recipientName;
  final double proposedPrice; // Precio propuesto en esta contraoferta
  final double? originalPrice; // Precio original propuesto por el cliente
  final String reason; // Razón de la contraoferta
  final String status; // pending, accepted, rejected, expired
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? responseReason;

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
