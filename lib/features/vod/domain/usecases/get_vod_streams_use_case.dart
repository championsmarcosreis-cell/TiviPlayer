import '../../../auth/domain/entities/xtream_session.dart';
import '../entities/vod_stream.dart';
import '../repositories/vod_repository.dart';

class GetVodStreamsUseCase {
  const GetVodStreamsUseCase(this._repository);

  final VodRepository _repository;

  Future<List<VodStream>> call(XtreamSession session, {String? categoryId}) {
    return _repository.getStreams(session, categoryId: categoryId);
  }
}
