import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/fishing_controller.dart';
import '../domain/fishing_models.dart';
import 'widgets/fishing_gameplay_view.dart';

class FishingScreen extends StatefulWidget {
  const FishingScreen({super.key});

  @override
  State<FishingScreen> createState() => _FishingScreenState();
}

class _FishingScreenState extends State<FishingScreen> {
  late FishingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FishingController(onStateChanged: () => setState(() {}));
    _controller.init().then((_) => _controller.startGame());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: Stack(
          children: [
            // The main game canvas
            FishingGameplayView(
              state: state,
              onShoot: _controller.shoot,
              onUpgrade: _controller.tryUpgrade,
              onOptionSelected: _controller.onOptionSelected,
            ),

            // Top HUD
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _hudItem("🪙", "${state.coins}", Colors.amber.shade700),
                  _hudItem("🎯", "${state.score}", Colors.white),
                  _hudItem("⚡", "${state.ammo}", Colors.greenAccent),
                ],
              ),
            ),

            // Back button
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hudItem(String icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
