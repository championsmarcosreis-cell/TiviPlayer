import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/live_remote_data_source.dart';
import '../../data/repositories/live_repository_impl.dart';
import '../../domain/entities/live_category.dart';
import '../../domain/entities/live_epg_entry.dart';
import '../../domain/entities/live_stream.dart';
import '../../domain/repositories/live_repository.dart';
import '../../domain/usecases/get_live_categories_use_case.dart';
import '../../domain/usecases/get_live_short_epg_use_case.dart';
import '../../domain/usecases/get_live_streams_use_case.dart';

final liveRemoteDataSourceProvider = Provider<LiveRemoteDataSource>((ref) {
  return LiveRemoteDataSource(ref.watch(xtreamClientProvider));
});

final liveRepositoryProvider = Provider<LiveRepository>((ref) {
  return LiveRepositoryImpl(ref.watch(liveRemoteDataSourceProvider));
});

final getLiveCategoriesUseCaseProvider = Provider<GetLiveCategoriesUseCase>(
  (ref) => GetLiveCategoriesUseCase(ref.watch(liveRepositoryProvider)),
);

final getLiveStreamsUseCaseProvider = Provider<GetLiveStreamsUseCase>(
  (ref) => GetLiveStreamsUseCase(ref.watch(liveRepositoryProvider)),
);

final getLiveShortEpgUseCaseProvider = Provider<GetLiveShortEpgUseCase>(
  (ref) => GetLiveShortEpgUseCase(ref.watch(liveRepositoryProvider)),
);

final liveCategoriesProvider = FutureProvider.autoDispose<List<LiveCategory>>((
  ref,
) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    return const <LiveCategory>[];
  }

  return ref.watch(getLiveCategoriesUseCaseProvider).call(session);
});

final liveStreamsProvider = FutureProvider.autoDispose
    .family<List<LiveStream>, String?>((ref, categoryId) async {
      final session = ref.watch(currentSessionProvider);
      if (session == null) {
        return const <LiveStream>[];
      }

      return ref
          .watch(getLiveStreamsUseCaseProvider)
          .call(session, categoryId: categoryId);
    });

final liveShortEpgProvider = FutureProvider.autoDispose
    .family<List<LiveEpgEntry>, String>((ref, streamId) async {
      final session = ref.watch(currentSessionProvider);
      if (session == null || streamId.trim().isEmpty) {
        return const <LiveEpgEntry>[];
      }

      return ref
          .watch(getLiveShortEpgUseCaseProvider)
          .call(session, streamId: streamId, limit: 3);
    });
