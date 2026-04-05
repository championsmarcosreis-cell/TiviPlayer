import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/features/kids/presentation/screens/kids_library_screen.dart';
import 'package:tiviplayer/features/series/domain/entities/series_category.dart';
import 'package:tiviplayer/features/series/domain/entities/series_item.dart';
import 'package:tiviplayer/features/series/presentation/providers/series_providers.dart';
import 'package:tiviplayer/features/vod/domain/entities/vod_category.dart';
import 'package:tiviplayer/features/vod/domain/entities/vod_stream.dart';
import 'package:tiviplayer/features/vod/presentation/providers/vod_providers.dart';

void main() {
  testWidgets(
    'biblioteca Kids ignora categorias e itens apenas textuais sem library_kind',
    (tester) async {
      await _pumpKidsLibraryScreen(
        tester,
        vodCategories: const <VodCategory>[
          VodCategory(id: '10', name: 'Infantil'),
        ],
        vodItems: const <VodStream>[
          VodStream(id: '11', categoryId: '10', name: 'Turma da Floresta'),
        ],
        seriesCategories: const <SeriesCategory>[
          SeriesCategory(id: '20', name: 'Kids Shows'),
        ],
        seriesItems: const <SeriesItem>[
          SeriesItem(
            id: '21',
            categoryId: '20',
            name: 'Patrulha Mirim',
            plot: 'Conteúdo infantil sem sinal canônico.',
          ),
        ],
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Nenhum conteúdo Kids apareceu neste acesso.'),
        findsOne,
      );
      expect(find.text('Turma da Floresta'), findsNothing);
      expect(find.text('Patrulha Mirim'), findsNothing);
    },
  );

  testWidgets(
    'biblioteca Kids mostra conteúdo quando o servidor traz library_kind explicito',
    (tester) async {
      await _pumpKidsLibraryScreen(
        tester,
        vodCategories: const <VodCategory>[
          VodCategory(id: '10', name: 'Infantil', libraryKind: 'kids'),
        ],
        vodItems: const <VodStream>[
          VodStream(
            id: '11',
            categoryId: '10',
            name: 'Turma da Floresta',
            libraryKind: 'kids',
          ),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('Turma da Floresta'), findsOneWidget);
      expect(
        find.text('Nenhum conteúdo Kids apareceu neste acesso.'),
        findsNothing,
      );
    },
  );
}

Future<void> _pumpKidsLibraryScreen(
  WidgetTester tester, {
  List<VodCategory> vodCategories = const <VodCategory>[],
  List<VodStream> vodItems = const <VodStream>[],
  List<SeriesCategory> seriesCategories = const <SeriesCategory>[],
  List<SeriesItem> seriesItems = const <SeriesItem>[],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 720);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vodCategoriesProvider.overrideWith((ref) async => vodCategories),
        vodStreamsProvider.overrideWith((ref, categoryId) async => vodItems),
        seriesCategoriesProvider.overrideWith((ref) async => seriesCategories),
        seriesItemsProvider.overrideWith(
          (ref, categoryId) async => seriesItems,
        ),
      ],
      child: const MaterialApp(home: KidsLibraryScreen()),
    ),
  );
}
