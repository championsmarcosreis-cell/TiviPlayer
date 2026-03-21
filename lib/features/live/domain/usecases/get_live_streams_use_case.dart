import '../../../auth/domain/entities/xtream_session.dart';
import '../entities/live_stream.dart';
import '../repositories/live_repository.dart';

class GetLiveStreamsUseCase {
  const GetLiveStreamsUseCase(this._repository);

  final LiveRepository _repository;

  Future<List<LiveStream>> call(XtreamSession session, {String? categoryId}) {
    return _repository.getStreams(session, categoryId: categoryId);
  }
}
