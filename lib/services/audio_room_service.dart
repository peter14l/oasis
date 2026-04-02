/*
import 'package:oasis_v2/models/audio_room.dart';
import 'package:oasis_v2/services/supabase_service.dart';

class AudioRoomService {
  final _supabase = SupabaseService().client;

  /// Creates a new audio room. Pro feature only.
  Future<AudioRoom> createRoom({
    required String title,
    String? topic,
    RoomPrivacy privacy = RoomPrivacy.public,
  }) async {
    final user = _supabase.auth.currentUser;
    final isPro = user?.userMetadata?['is_pro'] == true;

    if (!isPro) {
      throw Exception('Upgrade to Morrow Pro to host an Audio Room.');
    }

    // Placeholder for actual live blocks integration (e.g., Agora or LiveKit)
    throw UnimplementedError(
      'Audio room creation backend infrastructure is pending.',
    );
  }
}
*/
