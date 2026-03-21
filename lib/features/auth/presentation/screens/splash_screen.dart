import 'package:flutter/material.dart';

import '../../../../shared/widgets/brand_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const routePath = '/';

  @override
  Widget build(BuildContext context) {
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
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandLogo(width: 220),
                      const SizedBox(height: 28),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        'Preparando sua sessão',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Carregando preferências e acesso salvo neste aparelho.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
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
