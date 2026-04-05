import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oasis/services/energy_meter_service.dart';

/// Persistent overlay widget displaying user's interaction energy
/// Shows as a subtle, dynamic circular indicator
class EnergyMeterWidget extends StatefulWidget {
  final Widget child;
  final bool showLabel;

  const EnergyMeterWidget({
    super.key,
    required this.child,
    this.showLabel = false,
  });

  @override
  State<EnergyMeterWidget> createState() => _EnergyMeterWidgetState();
}

class _EnergyMeterWidgetState extends State<EnergyMeterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnergyMeterService>(
      builder: (context, energyService, child) {
        final state = energyService.state;
        final isLowEnergy = state.isLowEnergy;

        return Stack(
          children: [
            // Apply grayscale filter when energy is low
            if (isLowEnergy)
              ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0.2126, 0.7152, 0.0722, 0, 0, // Red channel
                  0.2126, 0.7152, 0.0722, 0, 0, // Green channel
                  0.2126, 0.7152, 0.0722, 0, 0, // Blue channel
                  0, 0, 0, 1, 0, // Alpha channel
                ]),
                child: widget.child,
              )
            else
              widget.child,

            // Energy meter indicator (top-right)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: ScaleTransition(
                scale: isLowEnergy ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                child: _buildEnergyIndicator(state),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }

  Widget _buildEnergyIndicator(state) {
    final theme = Theme.of(context);
    final percentage = state.energyPercentage;
    final color = state.energyColor;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular progress indicator
          SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              children: [
                // Background circle
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(
                    theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                // Progress circle
                CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                // Center icon
                Center(
                  child: Icon(
                    Icons.bolt,
                    size: 16,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          
          // Optional label
          if (widget.showLabel) ...[
            const SizedBox(width: 8),
            Text(
              '${state.currentEnergy.toInt()}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
