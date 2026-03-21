import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/vod_remote_data_source.dart';
import '../../data/repositories/vod_repository_impl.dart';
import '../../domain/entities/vod_category.dart';
import '../../domain/entities/vod_info.dart';
import '../../domain/entities/vod_stream.dart';
import '../../domain/repositories/vod_repository.dart';
import '../../domain/usecases/get_vod_categories_use_case.dart';
import '../../domain/usecases/get_vod_info_use_case.dart';
import '../../domain/usecases/get_vod_streams_use_case.dart';

final vodRemoteDataSourceProvider = Provider<VodRemoteDataSource>((ref) {
  return VodRemoteDataSource(ref.watch(xtreamClientProvider));
});

final vodRepositoryProvider = Provider<VodRepository>((ref) {
  return VodRepositoryImpl(ref.watch(vodRemoteDataSourceProvider));
});

final getVodCategoriesUseCaseProvider = Provider<GetVodCategoriesUseCase>(
  (ref) => GetVodCategoriesUseCase(ref.watch(vodRepositoryProvider)),
);

final getVodStreamsUseCaseProvider = Provider<GetVodStreamsUseCase>(
  (ref) => GetVodStreamsUseCase(ref.watch(vodRepositoryProvider)),
);

final getVodInfoUseCaseProvider = Provider<GetVodInfoUseCase>(
  (ref) => GetVodInfoUseCase(ref.watch(vodRepositoryProvider)),
);

final vodCategoriesProvider = FutureProvider.autoDispose<List<VodCategory>>((
  ref,
) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    return const <VodCategory>[];
  }

  return ref.watch(getVodCategoriesUseCaseProvider).call(session);
});

final vodStreamsProvider = FutureProvider.autoDispose
    .family<List<VodStream>, String?>((ref, categoryId) async {
      final session = ref.watch(currentSessionProvider);
      if (session == null) {
        return const <VodStream>[];
      }

      return ref
          .watch(getVodStreamsUseCaseProvider)
          .call(session, categoryId: categoryId);
    });

final vodInfoProvider = FutureProvider.autoDispose.family<VodInfo, String>((
  ref,
  vodId,
) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    throw StateError('Sessão indisponível.');
  }

  return ref.watch(getVodInfoUseCaseProvider).call(session, vodId);
});
