import 'package:flutter/material.dart';

import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/widgets/brand_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const routePath = '/';

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF04070C),
                  Color(0xFF0B1221),
                  Color(0xFF05090E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x33FF6A1A), Color(0x00FF6A1A)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x3316C7FF), Color(0x00E33DFF)],
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: layout.isTv ? 560 : 420),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(layout.cardPadding + 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandWordmark(
                        height: layout.isTv ? 84 : 60,
                        compact: !layout.isTv,
                        showTagline: layout.isTv,
                      ),
                      SizedBox(height: layout.sectionSpacing + 10),
                      const CircularProgressIndicator(),
                      SizedBox(height: layout.sectionSpacing + 4),
                      Text(
                        'Preparando sua sessão',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: layout.isTv ? 30 : 22,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Carregando preferências e acesso salvo neste aparelho.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: layout.isTv ? 17 : 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
