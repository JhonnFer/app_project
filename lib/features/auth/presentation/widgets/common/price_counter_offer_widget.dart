import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../data/datasources/notification_service.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../presentation/providers/session_provider.dart';

/// 💰 Widget para mostrar y manejar contrapropuestas de precio
class PriceCounterOfferWidget extends StatefulWidget {
  final String notificationId;
  final Map<String, dynamic> notificationData;
  final VoidCallback onRefresh;

  const PriceCounterOfferWidget({
    Key? key,
    required this.notificationId,
    required this.notificationData,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<PriceCounterOfferWidget> createState() =>
      _PriceCounterOfferWidgetState();
}

class _PriceCounterOfferWidgetState extends State<PriceCounterOfferWidget> {
  final _notificationService = NotificationService();
  late TextEditingController _rejectionReasonController;
  late UserEntity currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rejectionReasonController = TextEditingController();
    final session = SessionManager();
    currentUser = session.currentUser!;
  }

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  /// Aceptar la contraoferta
  Future<void> _acceptCounterOffer() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Aceptando contraoferta...'),
          ],
        ),
      ),
    );

    try {
      final success = await _notificationService.acceptPriceCounterOffer(
        negotiationId: widget.notificationData['negotiationId'],
        requestId: widget.notificationData['requestId'],
        acceptedByUserId: currentUser.uid,
        agreedPrice: widget.notificationData['proposedPrice'],
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contraoferta aceptada'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al aceptar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Mostrar diálogo para rechazar
  Future<void> _showRejectDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Contraoferta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Por qué rechazas esta contraoferta?'),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectionReasonController,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                hintText: 'Escribe tu razón...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _rejectionReasonController.text.isEmpty
                ? null
                : _rejectCounterOffer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  /// Rechazar la contraoferta
  Future<void> _rejectCounterOffer() async {
    if (_rejectionReasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa una razón'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Cerrar el diálogo de razón
    if (mounted) Navigator.pop(context);

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Rechazando contraoferta...'),
          ],
        ),
      ),
    );

    try {
      final success = await _notificationService.rejectPriceCounterOffer(
        negotiationId: widget.notificationData['negotiationId'],
        requestId: widget.notificationData['requestId'],
        rejectedByUserId: currentUser.uid,
        rejectionReason: _rejectionReasonController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contraoferta rechazada'),
            backgroundColor: Colors.orange,
          ),
        );
        _rejectionReasonController.clear();
        widget.onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al rechazar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final proposedPrice = widget.notificationData['proposedPrice'] ?? 0.0;
    final originalPrice = widget.notificationData['originalPrice'] ?? 0.0;
    final reason =
        widget.notificationData['reason'] ?? 'Sin razón especificada';
    final senderName =
        widget.notificationData['senderName'] ?? 'Usuario desconocido';
    final priceDifference = proposedPrice - originalPrice;
    final percentageDiff =
        ((priceDifference / originalPrice) * 100).toStringAsFixed(1);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: priceDifference < 0 ? Colors.red : Colors.green,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💰 Contraoferta de $senderName',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priceDifference < 0
                            ? 'Precio reducido'
                            : 'Precio aumentado',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              priceDifference < 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: priceDifference < 0
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$percentageDiff%',
                      style: TextStyle(
                        color: priceDifference < 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Comparación de precios
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Precio Original:'),
                        Text(
                          '\$${originalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Contraoferta:'),
                        Text(
                          '\$${proposedPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color:
                                priceDifference < 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Razón
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Razón:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _showRejectDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _acceptCounterOffer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
