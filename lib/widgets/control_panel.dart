import 'package:flutter/material.dart';
import '../theme.dart';

class ControlPanel extends StatelessWidget {
  final TextEditingController startController;
  final TextEditingController destinationController;
  final int readingCount;
  final String tripTime;
  final bool isTracking;
  final bool hasTripData;
  final String trackingStatusTitle;
  final String trackingStatusMessage;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onDownload;

  const ControlPanel({
    super.key,
    required this.startController,
    required this.destinationController,
    required this.readingCount,
    required this.tripTime,
    required this.isTracking,
    required this.hasTripData,
    required this.trackingStatusTitle,
    required this.trackingStatusMessage,
    required this.onStart,
    required this.onStop,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Text(
            'TRIP CONTROL',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Track Your Journey',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your route and start collecting road data.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),

          _RouteField(
            icon: '●',
            iconColor: AppColors.primary,
            label: 'Start Point',
            hint: 'Enter starting location',
            controller: startController,
          ),
          const SizedBox(height: 12),
          _RouteField(
            icon: '◆',
            iconColor: AppColors.danger,
            label: 'Destination',
            hint: 'Enter destination',
            controller: destinationController,
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _InfoBox(label: 'GPS Readings', value: '$readingCount'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoBox(label: 'Trip Time', value: tripTime),
              ),
            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isTracking ? null : onStart,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Start Tracker'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: isTracking ? onStop : null,
              icon: const Icon(Icons.stop, size: 18),
              label: const Text('Stop Tracker'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: hasTripData ? onDownload : null,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Download Trip CSV'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.panelBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: isTracking ? AppColors.dotActive : AppColors.dotIdle,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trackingStatusTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trackingStatusMessage,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Center(
            child: Text(
              'RoadSense AI • Road Safety Intelligence',
              style: TextStyle(fontSize: 9, color: Color(0xFF80868B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteField extends StatelessWidget {
  final String icon;
  final Color iconColor;
  final String label;
  final String hint;
  final TextEditingController controller;

  const _RouteField({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Text(icon, style: TextStyle(fontSize: 13, color: iconColor)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
