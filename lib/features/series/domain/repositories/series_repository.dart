import '../../../auth/domain/entities/xtream_session.dart';
import '../entities/series_category.dart';
import '../entities/series_info.dart';
import '../entities/series_item.dart';

abstract class SeriesRepository {
  Future<List<SeriesCategory>> getCategories(XtreamSession session);
  Future<List<SeriesItem>> getSeries(
    XtreamSession session, {
    String? categoryId,
  });
  Future<SeriesInfo> getInfo(XtreamSession session, String seriesId);
}
