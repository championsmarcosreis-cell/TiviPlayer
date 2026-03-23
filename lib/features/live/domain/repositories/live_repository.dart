import '../../../auth/domain/entities/xtream_session.dart';
import '../entities/live_category.dart';
import '../entities/live_epg_entry.dart';
import '../entities/live_stream.dart';

abstract class LiveRepository {
  Future<List<LiveCategory>> getCategories(XtreamSession session);
  Future<List<LiveStream>> getStreams(
    XtreamSession session, {
    String? categoryId,
  });
  Future<List<LiveEpgEntry>> getShortEpg(
    XtreamSession session, {
    required String streamId,
    int limit = 3,
  });
}
