import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/service_request_offer_entity.dart';
import '../../../../domain/repositories/offer_repository.dart';
import '../../../../domain/usecases/create_offer_usecase.dart';
import '../../../../domain/usecases/accept_offer_usecase.dart';
import '../../../../data/repositories/offer_firestore_repository.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../../presentation/providers/session_provider.dart';

class PriceNegotiationScreen extends StatefulWidget {
  final String requestId;
  final double initialPrice;
  final UserEntity? currentUser;

  const PriceNegotiationScreen({
    Key? key,
    required this.requestId,
    required this.initialPrice,
    this.currentUser,
  }) : super(key: key);

  @override
  State<PriceNegotiationScreen> createState() => _PriceNegotiationScreenState();
}

class _PriceNegotiationScreenState extends State<PriceNegotiationScreen> {
  late TextEditingController _priceController;
  late TextEditingController _reasonController;
  bool _isLoading = false;
  late UserEntity currentUser;
  late OfferRepository repository;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
    _reasonController = TextEditingController();
    final session = SessionManager();
    currentUser = session.currentUser ?? widget.currentUser!;
    repository = OfferFirestoreRepository(firestore: FirebaseFirestore.instance);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // Crear contraoferta (técnico o cliente)
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
      final offer = Offer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        requestId: widget.requestId,
        senderId: currentUser.uid,
        senderName: currentUser.name,
        recipientId: '', // opcional: cliente o técnico
        recipientName: '', // opcional
        proposedPrice: price,
        originalPrice: widget.initialPrice,
        reason: _reasonController.text.trim(),
        status: OfferStatus.pending,
        createdAt: DateTime.now(),
      );

      final createOfferUseCase = CreateOfferUseCase(repository);
      await createOfferUseCase.call(offer);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Oferta enviada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      _priceController.clear();
      _reasonController.clear();
    } catch (e) {
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

  // Aceptar oferta (solo cliente)
  Future<void> _acceptOffer(Offer offer) async {
    setState(() => _isLoading = true);
    try {
      final acceptUseCase = AcceptOfferUseCase(repository);
      await acceptUseCase.call(widget.requestId, offer.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Oferta aceptada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Formulario de nueva oferta
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Crear Oferta / Contraoferta', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Precio Propuesto',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      minLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Razón de la Oferta',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendCounterOffer,
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Enviar'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lista de ofertas existentes
            Expanded(
              child: StreamBuilder<List<Offer>>(
                stream: FirebaseFirestore.instance
                    .collection('offers')
                    .where('requestId', isEqualTo: widget.requestId)
                    .snapshots()
                    .map((snapshot) => snapshot.docs.map((doc) {
                          final data = doc.data();
                          return Offer(
                            id: doc.id,
                            requestId: data['requestId'],
                            senderId: data['senderId'],
                            senderName: data['senderName'],
                            recipientId: data['recipientId'] ?? '',
                            recipientName: data['recipientName'] ?? '',
                            proposedPrice: (data['proposedPrice'] as num).toDouble(),
                            originalPrice: data['originalPrice'] != null
                                ? (data['originalPrice'] as num).toDouble()
                                : null,
                            reason: data['reason'] ?? '',
                            status: OfferStatus.values.firstWhere(
                                (e) => e.name == (data['status'] ?? 'pending'),
                                orElse: () => OfferStatus.pending),
                            createdAt: DateTime.parse(data['createdAt']),
                            respondedAt: data['respondedAt'] != null
                                ? DateTime.parse(data['respondedAt'])
                                : null,
                            responseReason: data['responseReason'],
                          );
                        }).toList()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final offers = snapshot.data ?? [];
                  if (offers.isEmpty) return const Center(child: Text('No hay ofertas aún.'));

                  return ListView.builder(
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      final offer = offers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text('${offer.senderName} - \$${offer.proposedPrice}'),
                          subtitle: Text(offer.reason),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(offer.status.name),
                              const SizedBox(width: 8),
                              if (currentUser.role == 'client' && offer.status == OfferStatus.pending)
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: _isLoading ? null : () => _acceptOffer(offer),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
