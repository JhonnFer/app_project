import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_services.dart';

class ServiceChecklistWidget extends StatefulWidget {
  final List<ApplianceService> selectedServices;
  final Function(List<ApplianceService>) onServicesChanged;

  const ServiceChecklistWidget({
    Key? key,
    required this.selectedServices,
    required this.onServicesChanged,
  }) : super(key: key);

  @override
  State<ServiceChecklistWidget> createState() => _ServiceChecklistWidgetState();
}

class _ServiceChecklistWidgetState extends State<ServiceChecklistWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Servicios que ofreces',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecciona los servicios de línea blanca que puedes reparar',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: AppServices.whiteLinerServices.length,
          itemBuilder: (context, index) {
            final service = AppServices.whiteLinerServices[index];
            final isSelected = widget.selectedServices.contains(service);

            return _buildServiceCard(
              service: service,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    widget.selectedServices.remove(service);
                  } else {
                    widget.selectedServices.add(service);
                  }
                  widget.onServicesChanged(widget.selectedServices);
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required ApplianceService service,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.white,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
