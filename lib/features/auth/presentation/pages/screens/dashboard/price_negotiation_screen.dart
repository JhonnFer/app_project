import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PriceNegotiationsSection extends StatelessWidget {
  final String technicianId;

  const PriceNegotiationsSection({
    super.key,
    required this.technicianId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('price_negotiations')
          .where('recipientId', isEqualTo: technicianId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar negociaciones'));
        }

        final negotiations = snapshot.data?.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                ...data,
                'id': doc.id,
              };
            }).toList() ??
            [];

        if (negotiations.isEmpty) {
          return const Center(
            child: Text('No tienes negociaciones pendientes'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: negotiations.length,
          itemBuilder: (_, index) {
            final negotiation = negotiations[index];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(negotiation['reason'] ?? ''),
                subtitle: Text(
                  'Precio propuesto: \$${negotiation['proposedPrice']}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _updateStatus(
                        negotiation['id'],
                        'accepted',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _updateStatus(
                        negotiation['id'],
                        'rejected',
                      ),
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

  Future<void> _updateStatus(String id, String status) async {
    await FirebaseFirestore.instance
        .collection('price_negotiations')
        .doc(id)
        .update({'status': status});
  }
}
