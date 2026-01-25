import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../data/datasources/notification_service.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../../presentation/providers/session_provider.dart';

/// 💰 Pantalla de negociación de precios para técnicos y clientes
class PriceNegotiationScreen extends StatefulWidget {
  final String requestId;
  final String? initiatorId;
  final double initialPrice;
  final UserEntity? currentUser;

  const PriceNegotiationScreen({
    Key? key,
    required this.requestId,
    this.initiatorId,
    required this.initialPrice,
    this.currentUser,
  }) : super(key: key);

  @override
  State<PriceNegotiationScreen> createState() => _PriceNegotiationScreenState();
}

class _PriceNegotiationScreenState extends State<PriceNegotiationScreen> {
  late TextEditingController _priceController;
  late TextEditingController _reasonController;
  final _notificationService = NotificationService();
  bool _isLoading = false;
  late UserEntity currentUser;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
    _reasonController = TextEditingController();

    final session = SessionManager();
    currentUser = session.currentUser ?? widget.currentUser!;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  /// Enviar contraoferta
  Future<void> _sendCounterOffer() async {
    if (_priceController.text.isEmpty || _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un precio válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Obtener datos de la solicitud
      final serviceRequestDoc = await FirebaseFirestore.instance
          .collection('service_requests')
          .doc(widget.requestId)
          .get();

      if (!serviceRequestDoc.exists) {
        throw Exception('Solicitud no encontrada');
      }

      final serviceData = serviceRequestDoc.data() as Map<String, dynamic>;
      final recipientId = currentUser.role == 'client'
          ? serviceData['technician'] ?? serviceData['uid']
          : serviceData['uid'];
      final recipientName = currentUser.role == 'client'
          ? serviceData['technicianName'] ?? 'Técnico'
          : serviceData['clientName'];

      // Enviar contraoferta
      final success = await _notificationService.sendPriceCounterOffer(
        requestId: widget.requestId,
        senderId: currentUser.uid,
        senderName: currentUser.name,
        recipientId: recipientId,
        recipientName: recipientName,
        proposedPrice: price,
        originalPrice: widget.initialPrice,
        reason: _reasonController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contraoferta enviada correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al enviar la contraoferta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Negociación de Precio'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información de la solicitud
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información de la Solicitud',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Precio Propuesto:'),
                          Text(
                            '\$${widget.initialPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Formulario de contraoferta
              Text(
                'Tu Contraoferta',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              // Campo de precio
              Text(
                'Precio Propuesto',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Ej: 75000',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),

              // Campo de razón
              Text(
                'Razón de la Contraoferta',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                minLines: 2,
                decoration: InputDecoration(
                  hintText:
                      'Explica por qué propones este precio (ej: Costos de materiales, dificultad del trabajo, etc.)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                ),
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendCounterOffer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
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
                          : const Text('Enviar Contraoferta'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
