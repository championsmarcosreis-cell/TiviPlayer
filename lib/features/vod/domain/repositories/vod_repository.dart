import '../../../auth/domain/entities/xtream_session.dart';
import '../entities/vod_category.dart';
import '../entities/vod_info.dart';
import '../entities/vod_stream.dart';

abstract class VodRepository {
  Future<List<VodCategory>> getCategories(XtreamSession session);
  Future<List<VodStream>> getStreams(
    XtreamSession session, {
    String? categoryId,
  });
  Future<VodInfo> getInfo(XtreamSession session, String vodId);
}
