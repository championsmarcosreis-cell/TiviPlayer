import '../../../auth/domain/entities/xtream_session.dart';
import '../entities/live_epg_entry.dart';
import '../repositories/live_repository.dart';

class GetLiveShortEpgUseCase {
  const GetLiveShortEpgUseCase(this._repository);

  final LiveRepository _repository;

  Future<List<LiveEpgEntry>> call(
    XtreamSession session, {
    required String streamId,
    int limit = 3,
  }) {
    return _repository.getShortEpg(session, streamId: streamId, limit: limit);
  }
}
