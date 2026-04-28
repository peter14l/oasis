import 'package:flutter/foundation.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:oasis/features/wellbeing/domain/models/garden_plot_entity.dart';

class DigitalGardenService {
  final SupabaseService _supabaseService = SupabaseService();

  Future<List<GardenPlotEntity>> getUserGarden(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('garden_plots')
          .select()
          .eq('user_id', userId)
          .order('planted_at', ascending: true);
          
      return (response as List).map((json) => GardenPlotEntity.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[DigitalGardenService] Error fetching garden: $e');
      return [];
    }
  }

  Future<GardenPlotEntity?> plantSeed({
    required String userId,
    required String seedText,
    required double xPos,
    required double yPos,
  }) async {
    try {
      final response = await _supabaseService.client
          .from('garden_plots')
          .insert({
            'user_id': userId,
            'seed_text': seedText,
            'stage': 0,
            'x_pos': xPos,
            'y_pos': yPos,
          })
          .select()
          .single();
          
      return GardenPlotEntity.fromJson(response);
    } catch (e) {
      debugPrint('[DigitalGardenService] Error planting seed: $e');
      return null;
    }
  }

  Future<void> tendPlot(String plotId, int currentStage) async {
    try {
      // Increase stage up to max of 3 (blooming)
      final newStage = currentStage < 3 ? currentStage + 1 : 3;
      
      await _supabaseService.client
          .from('garden_plots')
          .update({
            'stage': newStage,
            'last_tended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', plotId);
    } catch (e) {
      debugPrint('[DigitalGardenService] Error tending plot: $e');
    }
  }

  Future<void> removePlot(String plotId) async {
    try {
      await _supabaseService.client
          .from('garden_plots')
          .delete()
          .eq('id', plotId);
    } catch (e) {
      debugPrint('[DigitalGardenService] Error removing plot: $e');
    }
  }
}
