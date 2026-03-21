import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/series_remote_data_source.dart';
import '../../data/repositories/series_repository_impl.dart';
import '../../domain/entities/series_category.dart';
import '../../domain/entities/series_info.dart';
import '../../domain/entities/series_item.dart';
import '../../domain/repositories/series_repository.dart';
import '../../domain/usecases/get_series_categories_use_case.dart';
import '../../domain/usecases/get_series_info_use_case.dart';
import '../../domain/usecases/get_series_items_use_case.dart';

final seriesRemoteDataSourceProvider = Provider<SeriesRemoteDataSource>((ref) {
  return SeriesRemoteDataSource(ref.watch(xtreamClientProvider));
});

final seriesRepositoryProvider = Provider<SeriesRepository>((ref) {
  return SeriesRepositoryImpl(ref.watch(seriesRemoteDataSourceProvider));
});

final getSeriesCategoriesUseCaseProvider = Provider<GetSeriesCategoriesUseCase>(
  (ref) => GetSeriesCategoriesUseCase(ref.watch(seriesRepositoryProvider)),
);

final getSeriesItemsUseCaseProvider = Provider<GetSeriesItemsUseCase>(
  (ref) => GetSeriesItemsUseCase(ref.watch(seriesRepositoryProvider)),
);

final getSeriesInfoUseCaseProvider = Provider<GetSeriesInfoUseCase>(
  (ref) => GetSeriesInfoUseCase(ref.watch(seriesRepositoryProvider)),
);

final seriesCategoriesProvider =
    FutureProvider.autoDispose<List<SeriesCategory>>((ref) async {
      final session = ref.watch(currentSessionProvider);
      return ref.watch(getSeriesCategoriesUseCaseProvider).call(session);
    });

final seriesItemsProvider = FutureProvider.autoDispose
    .family<List<SeriesItem>, String?>((ref, categoryId) async {
      final session = ref.watch(currentSessionProvider);
      return ref
          .watch(getSeriesItemsUseCaseProvider)
          .call(session, categoryId: categoryId);
    });

final seriesInfoProvider = FutureProvider.autoDispose
    .family<SeriesInfo, String>((ref, seriesId) async {
      final session = ref.watch(currentSessionProvider);
      return ref.watch(getSeriesInfoUseCaseProvider).call(session, seriesId);
    });
