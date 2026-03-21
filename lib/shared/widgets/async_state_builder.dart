import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failure.dart';
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(
                variant: BrandLogoVariant.icon,
                width: 56,
                height: 56,
              ),
              const SizedBox(height: 18),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Carregando conteúdo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
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
