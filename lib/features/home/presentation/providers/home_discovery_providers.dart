import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/home_discovery_remote_data_source.dart';
import '../../data/models/home_discovery_dto.dart';

final homeDiscoveryRemoteDataSourceProvider =
    Provider<HomeDiscoveryRemoteDataSource>((ref) {
      return HomeDiscoveryRemoteDataSource(ref.watch(dioProvider));
    });

final homeDiscoveryProvider = FutureProvider.autoDispose
    .family<HomeDiscoveryDto?, int>((ref, limit) async {
      final session = ref.watch(currentSessionProvider);
      if (session == null) {
        return null;
      }

      return ref
          .watch(homeDiscoveryRemoteDataSourceProvider)
          .fetchHome(session, limit: limit);
    });
