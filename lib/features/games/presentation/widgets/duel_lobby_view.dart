import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/speed_duel_models.dart';

class DuelLobbyView extends StatelessWidget {
  final int setupStep;
  final DuelMode selectedMode;
  final double difficulty;
  final List<BotInfo> allBots;
  final List<BotInfo> selectedBots;
  final Function(DuelMode) onModeSelected;
  final Function(double) onDifficultySelected;
  final Function(BotInfo) onBotToggled;
  final VoidCallback onPrevStep;
  final VoidCallback onNextStep;

  const DuelLobbyView({
    super.key,
    required this.setupStep,
    required this.selectedMode,
    required this.difficulty,
    required this.allBots,
    required this.selectedBots,
    required this.onModeSelected,
    required this.onDifficultySelected,
    required this.onBotToggled,
    required this.onPrevStep,
    required this.onNextStep,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const Divider(height: 1),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: _getStepContent(colorScheme),
          ),
        ),
        // Step Navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (setupStep > 0)
                TextButton.icon(
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4)),
                  onPressed: onPrevStep,
                  icon: const Icon(Icons.chevron_left, size: 20),
                  label: const Text("Quay lại", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              if (setupStep == 2) ...[
                const SizedBox(width: 24),
                ElevatedButton.icon(
                  onPressed: onNextStep,
                  icon: const Icon(Icons.flash_on_rounded, size: 18),
                  label: const Text("VÀO TRẬN!", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _getStepContent(ColorScheme colorScheme) {
    switch (setupStep) {
      case 0: return _stepChooseMode(colorScheme);
      case 1: return _stepChooseDifficulty(colorScheme);
      case 2: return _stepChooseBots(colorScheme);
      default: return const SizedBox();
    }
  }

  Widget _stepChooseMode(ColorScheme colorScheme) {
    return Center(
      key: const ValueKey(0),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _modeSelector(DuelMode.recognize, "Nhìn Chọn", "🧩")),
            const SizedBox(width: 24),
            Expanded(child: _modeSelector(DuelMode.read, "Nghe Đọc", "🎙️")),
          ],
        ),
      ),
    );
  }

  Widget _stepChooseDifficulty(ColorScheme colorScheme) {
    return Center(
      key: const ValueKey(1),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _diffCard(0.2, "Dễ", "🌟", Colors.green)),
            const SizedBox(width: 16),
            Expanded(child: _diffCard(0.5, "Vừa", "⚡", Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: _diffCard(0.9, "Khó", "🔥", Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _stepChooseBots(ColorScheme colorScheme) {
    return SingleChildScrollView(
      key: const ValueKey(2),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: allBots.map((bot) {
            bool isSelected = selectedBots.contains(bot);
            return GestureDetector(
              onTap: () => onBotToggled(bot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: isSelected ? bot.color.withValues(alpha: 0.3) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isSelected ? bot.color : Colors.grey.shade300, width: 3),
                  boxShadow: isSelected ? [BoxShadow(color: bot.color.withValues(alpha: 0.2), blurRadius: 10)] : null,
                ),
                child: Column(
                  children: [
                    Text(bot.avatar, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    Text(bot.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _modeSelector(DuelMode mode, String label, String icon) {
    bool active = selectedMode == mode;
    return GestureDetector(
      onTap: () async {
        onModeSelected(mode);
        // The callback in parent calls setState, but the parent should handle the delay 
        // if we want to wait before _nextStep.
        // Actually, it's safer to put the delay in the callback itself or here.
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: active ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: active ? Colors.blue : Colors.grey.shade300, width: 4),
          boxShadow: active ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 20)] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: FittedBox(child: Text(icon, style: const TextStyle(fontSize: 80)))),
            const SizedBox(height: 8),
            FittedBox(child: Text(label, style: GoogleFonts.handlee(fontSize: 22, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  Widget _diffCard(double val, String label, String icon, Color color) {
    bool isSel = difficulty == val;
    return GestureDetector(
      onTap: () => onDifficultySelected(val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: isSel ? color : Colors.grey.shade300, width: 4),
          boxShadow: isSel ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20)] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: FittedBox(child: Text(icon, style: const TextStyle(fontSize: 64)))),
            const SizedBox(height: 12),
            FittedBox(child: Text(label, style: GoogleFonts.handlee(fontSize: 24, fontWeight: FontWeight.bold, color: isSel ? color : Colors.black87))),
          ],
        ),
      ),
    );
  }
}
