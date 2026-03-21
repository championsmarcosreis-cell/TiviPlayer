import '../../../auth/domain/entities/xtream_session.dart';
import '../entities/vod_info.dart';
import '../repositories/vod_repository.dart';

class GetVodInfoUseCase {
  const GetVodInfoUseCase(this._repository);

  final VodRepository _repository;

  Future<VodInfo> call(XtreamSession session, String vodId) {
    return _repository.getInfo(session, vodId);
  }
}
