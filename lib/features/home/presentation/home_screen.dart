import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/signals/app_signals.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();

  void _onEnter() {
    if (_controller.text.trim().isNotEmpty) {
      selectWord(_controller.text.trim());
      _controller.clear();
      context.push('/learn');
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = historySignal.watch(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'),
              opacity: 0.05,
              colorFilter: ColorFilter.mode(colorScheme.primary.withOpacity(0.1), BlendMode.srcIn),
            ),
          ),
          child: Stack(
            children: [
              Row(
                children: [
            // Left Side: Branding & Input
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sticker-like Logo
                    Transform.rotate(
                      angle: -0.05,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: colorScheme.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Text(
                          "Doraebin",
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Học đánh vần tiếng Việt thật vui!",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: colorScheme.primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "Nhập một từ muốn học...",
                          hintStyle: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.primary.withOpacity(0.4)),
                          prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                          fillColor: Colors.transparent,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: IconButton(
                              icon: CircleAvatar(
                                backgroundColor: colorScheme.primaryContainer,
                                child: Icon(Icons.arrow_forward_rounded, color: colorScheme.onPrimaryContainer),
                              ),
                              onPressed: _onEnter,
                            ),
                          ),
                        ),
                        style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.primary),
                        onSubmitted: (_) => _onEnter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Right Side: History (Scrollable)
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: colorScheme.primary.withOpacity(0.05), blurRadius: 30),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        "Những từ đã học",
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = history[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              title: Text(
                                item['text'],
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                onPressed: () => deleteFromHistory(item['id']),
                              ),
                              onTap: () {
                                selectWord(item['text']);
                                context.push('/learn');
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
              // Back Button
              Positioned(
                top: 16,
                left: 16,
                child: IconButton.filled(
                  onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerLowest,
                    foregroundColor: colorScheme.primary,
                    elevation: 4,
                    shadowColor: colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
