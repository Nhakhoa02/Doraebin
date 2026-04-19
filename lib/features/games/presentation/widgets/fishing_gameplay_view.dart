import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/fishing_models.dart';

class FishingGameplayView extends StatelessWidget {
  final FishingGameState state;
  final Function(Offset) onShoot;
  final VoidCallback onUpgrade;
  final Function(String) onOptionSelected;

  const FishingGameplayView({
    super.key,
    required this.state,
    required this.onShoot,
    required this.onUpgrade,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Map virtual 1000x1000 coords to screen pixels
        Offset toScreen(Offset virtual) => Offset(
              virtual.dx * width / 1000,
              virtual.dy * height / 1000,
            );

        Offset fromScreen(Offset screen) => Offset(
              screen.dx * 1000 / width,
              screen.dy * 1000 / height,
            );

        return GestureDetector(
          onTapDown: (details) => onShoot(fromScreen(details.localPosition)),
          child: Container(
            color: Colors.transparent, // Background gradient is in the Screen
            child: Stack(
              children: [
                // 1. Seaweed/Bubbles (Animated)
                // (Adding these later for polish)

                // 2. Fish
                ...state.activeFish.map((fish) {
                  final screenPos = toScreen(fish.position);
                  return Positioned(
                    left: screenPos.dx - (fish.width / 2),
                    top: screenPos.dy - (fish.height / 2),
                    child: Transform.flip(
                      flipX: !fish.isMovingRight,
                      child: Text(
                        fish.emoji,
                        style: TextStyle(fontSize: fish.width),
                      ),
                    ),
                  );
                }),

                // 3. Projectiles (Nets)
                ...state.activeProjectiles.map((p) {
                  final screenPos = toScreen(p.position);
                  return Positioned(
                    left: screenPos.dx - p.radius,
                    top: screenPos.dy - p.radius,
                    child: Container(
                      width: p.radius * 2,
                      height: p.radius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: const Center(
                        child: Icon(Icons.grid_4x4_rounded, color: Colors.white70, size: 20),
                      ),
                    ),
                  );
                }),

                // 4. Cannon
                Positioned(
                  bottom: -20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: 0, // We could add rotation target later
                          child: Container(
                            width: 60,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              border: Border.all(color: Colors.amber, width: 3),
                            ),
                            child: Center(
                              child: Text(
                                "LV${state.cannonLevel}",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        
                        // Upgrade Button
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: ElevatedButton(
                            onPressed: state.coins >= (state.cannonLevel * 100) && state.phase == FishingPhase.playing 
                              ? onUpgrade : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            ),
                            child: Text("Nâng cấp (${state.cannonLevel * 100}🪙)"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Overlays
                if (state.phase == FishingPhase.rechargeTask)
                  _buildTaskOverlay(
                    context,
                    title: "HẾT ĐẠN RỒI!",
                    subtitle: "Đọc to chữ này để nạp thêm đạn:",
                    word: state.currentTaskWord ?? "",
                    showOptions: false,
                  ),

                if (state.phase == FishingPhase.evolutionTask)
                  _buildTaskOverlay(
                    context,
                    title: "GIAI ĐOẠN TIẾN HÓA",
                    subtitle: state.currentTaskType == QuizType.read 
                      ? "Đọc to chữ này (${state.upgradeStreak + 1}/3):"
                      : "Tìm chữ này (${state.upgradeStreak + 1}/3):",
                    word: state.currentTaskWord ?? "",
                    showOptions: state.currentTaskType == QuizType.recognize,
                    options: state.taskOptions,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskOverlay(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String word,
    required bool showOptions,
    List<String>? options,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: Colors.black.withOpacity(0.8),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Target Word
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  word,
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),

              if (state.isListening)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      const Icon(Icons.mic, color: Colors.blue, size: 48),
                      Text("Đang nghe: ${state.recognizedWords}"),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              if (showOptions && options != null)
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: options.map((opt) {
                    return ElevatedButton(
                      onPressed: () => onOptionSelected(opt),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        textStyle: const TextStyle(fontSize: 24),
                      ),
                      child: Text(opt),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
