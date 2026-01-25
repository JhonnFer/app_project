import 'package:cloud_firestore/cloud_firestore.dart';

/// 💰 Modelo para contrapropuestas de precio en negociación
class PriceNegotiationModel {
  final String id;
  final String requestId;
  final String
      senderId; // Usuario que envía la contraoferta (técnico o cliente)
  final String senderName;
  final String recipientId; // Usuario que recibe la contraoferta
  final String recipientName;
  final double proposedPrice; // Precio propuesto en esta contraoferta
  final double? originalPrice; // Precio original propuesto por el cliente
  final String
      reason; // Razón de la contraoferta (ej: "Precio muy bajo", "Necesito cubrir costos")
  final String status; // pending, accepted, rejected, expired
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? responseReason;

  PriceNegotiationModel({
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

  /// Convertir a JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'senderId': senderId,
      'senderName': senderName,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'proposedPrice': proposedPrice,
      'originalPrice': originalPrice,
      'reason': reason,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'responseReason': responseReason,
    };
  }

  /// Crear desde documento de Firestore
  factory PriceNegotiationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PriceNegotiationModel(
      id: doc.id,
      requestId: data['requestId'] as String,
      senderId: data['senderId'] as String,
      senderName: data['senderName'] as String,
      recipientId: data['recipientId'] as String,
      recipientName: data['recipientName'] as String,
      proposedPrice: (data['proposedPrice'] as num).toDouble(),
      originalPrice: data['originalPrice'] != null
          ? (data['originalPrice'] as num).toDouble()
          : null,
      reason: data['reason'] as String,
      status: data['status'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      responseReason: data['responseReason'] as String?,
    );
  }

  /// Crear copia con modificaciones (copyWith)
  PriceNegotiationModel copyWith({
    String? id,
    String? requestId,
    String? senderId,
    String? senderName,
    String? recipientId,
    String? recipientName,
    double? proposedPrice,
    double? originalPrice,
    String? reason,
    String? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? responseReason,
  }) {
    return PriceNegotiationModel(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      responseReason: responseReason ?? this.responseReason,
    );
  }
}
