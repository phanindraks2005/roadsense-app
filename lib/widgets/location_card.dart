import 'package:flutter/material.dart';
import '../theme.dart';

class LocationCard extends StatelessWidget {
  final String text;

  const LocationCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(60, 64, 67, 0.20),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.iconBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Current Location',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
