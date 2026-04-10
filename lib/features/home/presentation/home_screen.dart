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

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'),
            opacity: 0.05,
            colorFilter: ColorFilter.mode(const Color(0xFF776300).withOpacity(0.1), BlendMode.srcIn),
          ),
        ),
        child: Row(
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
                          color: const Color(0xFFFDD400),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF776300).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Text(
                          "Doraebin",
                          style: GoogleFonts.fredoka(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF433700),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Học đánh vần tiếng Việt thật vui!",
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF776300).withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF776300).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "Nhập một từ muốn học...",
                          hintStyle: GoogleFonts.beVietnamPro(color: const Color(0xFF776300).withOpacity(0.4)),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF776300)),
                          fillColor: Colors.transparent,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: IconButton(
                              icon: const CircleAvatar(
                                backgroundColor: Color(0xFFFDD400),
                                child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF433700)),
                              ),
                              onPressed: _onEnter,
                            ),
                          ),
                        ),
                        style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF776300)),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF776300).withOpacity(0.05), blurRadius: 30),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        "Những từ đã học",
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF776300),
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
                              color: const Color(0xFFFFFBF0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              title: Text(
                                item['text'],
                                style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF776300)),
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
      ),
    );
  }
}
