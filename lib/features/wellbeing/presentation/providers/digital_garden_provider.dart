import 'package:flutter/material.dart';
import 'package:oasis/features/wellbeing/domain/models/garden_plot_entity.dart';
import 'package:oasis/features/wellbeing/data/digital_garden_service.dart';

class DigitalGardenProvider extends ChangeNotifier {
  final DigitalGardenService _service = DigitalGardenService();

  List<GardenPlotEntity> _plots = [];
  List<GardenPlotEntity> get plots => _plots;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadGarden(String userId) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    _plots = await _service.getUserGarden(userId);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> plantSeed(String userId, String text, double x, double y) async {
    final newPlot = await _service.plantSeed(
      userId: userId,
      seedText: text,
      xPos: x,
      yPos: y,
    );
    
    if (newPlot != null) {
      _plots.add(newPlot);
      notifyListeners();
    }
  }

  Future<void> tendPlot(String plotId) async {
    final index = _plots.indexWhere((p) => p.id == plotId);
    if (index != -1) {
      final plot = _plots[index];
      
      // Auto tend logic: you can only tend once a day
      final now = DateTime.now();
      if (plot.lastTendedAt.isBefore(now.subtract(const Duration(hours: 20)))) {
        await _service.tendPlot(plotId, plot.stage);
        
        final newStage = plot.stage < 3 ? plot.stage + 1 : 3;
        _plots[index] = plot.copyWith(
          stage: newStage,
          lastTendedAt: now,
        );
        notifyListeners();
      }
    }
  }
  
  Future<void> removePlot(String plotId) async {
    await _service.removePlot(plotId);
    _plots.removeWhere((p) => p.id == plotId);
    notifyListeners();
  }
}
