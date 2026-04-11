import 'package:go_router/go_router.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/spelling/presentation/spelling_screen.dart';

import 'package:flutter/material.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';

import '../../features/games/presentation/word_builder_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/learning',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/learn',
      builder: (context, state) => const SpellingScreen(),
    ),
    // Games
    GoRoute(
      path: '/game/builder',
      builder: (context, state) => const WordBuilderScreen(),
    ),
    GoRoute(
      path: '/game/sound',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Sound Match')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Back to Dashboard'),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/game/bubble',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Bubble Pop')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Back to Dashboard'),
          ),
        ),
      ),
    ),
  ],
);
