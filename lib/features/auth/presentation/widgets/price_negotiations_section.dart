import 'package:flutter/material.dart';

import '../../domain/usecases/get_pending_negotiations_usecase.dart';
import '../../domain/usecases/respond_to_negotiation_usecase.dart';
import '../../domain/entities/price_negotiation_entity.dart';

class PriceNegotiationsSection extends StatelessWidget {
  final String recipientId;
  final GetPendingNegotiationsUseCase getNegotiations;
  final RespondToNegotiationUseCase respond;

  const PriceNegotiationsSection({
    super.key,
    required this.recipientId,
    required this.getNegotiations,
    required this.respond,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PriceNegotiationEntity>>(
      stream: getNegotiations(recipientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final negotiations = snapshot.data ?? [];

        if (negotiations.isEmpty) {
          return const Center(
            child: Text('No hay negociaciones pendientes'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: negotiations.length,
          itemBuilder: (context, index) {
            final negotiation = negotiations[index];

            return Card(
              child: ListTile(
                title: Text(negotiation.senderName),
                subtitle: Text(
                  '\$${negotiation.originalPrice} → \$${negotiation.proposedPrice}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        respond.reject(
                          negotiationId: negotiation.id,
                          userId: recipientId,
                          reason: 'Rechazado por el usuario',
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                        respond.accept(
                          negotiationId: negotiation.id,
                          userId: recipientId,
                          agreedPrice: negotiation.proposedPrice,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
