import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failure.dart';
import '../presentation/layout/device_layout.dart';
import 'brand_logo.dart';
import 'empty_state.dart';

class AsyncStateBuilder<T> extends StatelessWidget {
  const AsyncStateBuilder({
    super.key,
    required this.value,
    required this.dataBuilder,
    this.emptyTitle = 'Sem dados',
    this.emptyMessage = 'Nenhum item foi encontrado.',
    this.isEmpty,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) dataBuilder;
  final String emptyTitle;
  final String emptyMessage;
  final bool Function(T data)? isEmpty;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (data) {
        final shouldRenderEmpty = isEmpty?.call(data) ?? false;
        if (shouldRenderEmpty) {
          return EmptyState(
            title: emptyTitle,
            message: emptyMessage,
            icon: Icons.inbox_outlined,
          );
        }

        return dataBuilder(data);
      },
      loading: () => Center(
        child: Builder(
          builder: (context) {
            final layout = DeviceLayout.of(context);

            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: layout.isTv ? 420 : 300),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(layout.cardPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandLogo(
                        variant: BrandLogoVariant.icon,
                        width: layout.isTv ? 72 : 56,
                        height: layout.isTv ? 72 : 56,
                      ),
                      SizedBox(height: layout.sectionSpacing),
                      const CircularProgressIndicator(),
                      SizedBox(height: layout.sectionSpacing),
                      Text(
                        'Carregando conteúdo',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontSize: layout.isTv ? 24 : 18),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      error: (error, stackTrace) => EmptyState(
        title: 'Falha ao carregar',
        message: Failure.fromError(error).message,
        icon: Icons.cloud_off_rounded,
      ),
    );
  }
}
