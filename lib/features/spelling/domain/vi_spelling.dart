import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Vietnamese syllable decomposition result (matches Python dict structure)
class DecomposedSyllable {
  final String initial;
  final String nucleus;   // called "main" in Python
  final String ending;
  final String tone;
  final String original;
  final String spellString;
  final String ttsString;

  DecomposedSyllable({
    required this.initial,
    required this.nucleus,
    required this.ending,
    required this.tone,
    required this.original,
    required this.spellString,
    required this.ttsString,
  });

  @override
  String toString() => '[$original]: $spellString';
}

// ==================== CONSTANTS ====================

const List<String> INITIALS = [
  "ngh", "ng", "gh", "gi", "qu", "ch", "kh", "nh", "ph", "th", "tr",
  "b", "c", "d", "đ", "g", "h", "k", "l", "m", "n", "p", "q", "r",
  "s", "t", "v", "x",
];

const List<String> ENDINGS = ["ch", "nh", "ng", "c", "m", "n", "p", "t"];

const Map<String, Map<String, String>> _GI_SPECIAL_CASES = {
  "gì": {
    "initial": "gi",
    "main": "",
    "ending": "",
    "tone": "Huyền",
    "spell": "gi huyền gì",
    "tts": "gi huyền gì",
  },
  "gìn": {
    "initial": "gi",
    "main": "in",
    "ending": "",
    "tone": "Huyền",
    "spell": "gi in gin huyền gìn",
    "tts": "gi in gin huyền gìn",
  },
  "giếng": {
    "initial": "gi",
    "main": "iêng",
    "ending": "",
    "tone": "Sắc",
    "spell": "gi iêng giêng sắc giếng",
    "tts": "gi iêng giêng sắc giếng",
  },
  "giềng": {
    "initial": "gi",
    "main": "iêng",
    "ending": "",
    "tone": "Huyền",
    "spell": "gi iêng giêng huyền giềng",
    "tts": "gi iêng giêng huyền giềng",
  },
  "giết": {
    "initial": "gi",
    "main": "iết",
    "ending": "",
    "tone": "Sắc",
    "spell": "gi iết giết sắc giết",
    "tts": "gi iết giết sắc giết",
  },
  "giêng": {
    "initial": "gi",
    "main": "iêng",
    "ending": "",
    "tone": "Ngang",
    "spell": "gi iêng giêng",
    "tts": "gi iêng giêng",
  },
};

const Map<String, String> TONE_MAP = {
  "\u0300": "Huyền",
  "\u0309": "Hỏi",
  "\u0303": "Ngã",
  "\u0301": "Sắc",
  "\u0323": "Nặng",
};

const String VOWEL_ORDER = "aăâeêoôơiuưy";

// ==================== HELPER FUNCTIONS ====================

/// Add Vietnamese tone mark (exactly same logic as Python `add_tone`)
String addTone(String syllable, String tone) {
  if (syllable.isEmpty || tone == "" || tone == "0") return syllable;

  const toneSymbols = {
    "s": "\u0301", // sắc
    "f": "\u0300", // huyền
    "r": "\u0323", // nặng
    "x": "\u0309", // hỏi
    "j": "\u0303", // ngã
  };

  final combining = toneSymbols[tone.toLowerCase()] ?? "";
  if (combining.isEmpty) return syllable;

  int bestPos = -1;
  int bestPriority = VOWEL_ORDER.length;

  for (int i = 0; i < syllable.length; i++) {
    final lower = syllable[i].toLowerCase();
    final priority = VOWEL_ORDER.indexOf(lower);
    if (priority != -1 && priority < bestPriority) {
      bestPriority = priority;
      bestPos = i;
    }
  }

  if (bestPos == -1) return syllable;

  return syllable.substring(0, bestPos + 1) +
      combining +
      syllable.substring(bestPos + 1);
}

/// Main decomposition function - **Strictly follows Python logic**
DecomposedSyllable decomposeVietnameseSyllable(String word) {
  if (word.isEmpty) {
    return DecomposedSyllable(
      initial: "",
      nucleus: "",
      ending: "",
      tone: "Ngang",
      original: word,
      spellString: "",
      ttsString: "",
    );
  }

  final lowerWord = word.toLowerCase();

  // 1. Special cases for "gi"
  if (_GI_SPECIAL_CASES.containsKey(lowerWord)) {
    final sp = _GI_SPECIAL_CASES[lowerWord]!;
    return DecomposedSyllable(
      initial: sp["initial"]!,
      nucleus: sp["main"]!.isEmpty ? "(none)" : sp["main"]!,
      ending: sp["ending"]!.isEmpty ? "(none)" : sp["ending"]!,
      tone: sp["tone"]!,
      original: word,
      spellString: sp["spell"]!,
      ttsString: sp["tts"]!,
    );
  }

  // 2. Normalize to NFD and extract tone
  final normalized = unorm.nfd(lowerWord);

  String tone = "Ngang";
  for (final char in normalized.split('')) {
    if (TONE_MAP.containsKey(char)) {
      tone = TONE_MAP[char]!;
      break;
    }
  }

  // Remove tone marks
  final base = normalized.split('').where((c) => !TONE_MAP.containsKey(c)).join();

  // 3. Find initial consonant
  final chars = base.split('');
  String initial = "";
  int i = 0;

  final sortedInitials = List<String>.from(INITIALS)
    ..sort((a, b) => b.length.compareTo(a.length));

  for (final init in sortedInitials) {
    if (chars.length >= init.length &&
        chars.sublist(0, init.length).join() == init) {
      initial = init;
      i = init.length;
      break;
    }
  }

  List<String> remaining = chars.sublist(i);

  // 4. Find ending consonant
  String ending = "";
  if (remaining.isNotEmpty) {
    final sortedEndings = List<String>.from(ENDINGS)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final end in sortedEndings) {
      final endLen = end.length;
      if (remaining.length >= endLen &&
          remaining.sublist(remaining.length - endLen).join() == end) {
        ending = end;
        remaining = remaining.sublist(0, remaining.length - endLen);
        break;
      }
    }
  }

  // 5. Nucleus (main vowel)
  final main = remaining.join();
  final mainNfc = unorm.nfc(main);

  // 6. Build spelling parts (exactly as Python)
  List<String> parts = [];

  // Handle "qu" special case
  String currentMain = mainNfc;
  if (initial == "qu" && ending.isNotEmpty) {
    currentMain = "u" + mainNfc;
  }

  // 1. Spell main vowel letter by letter
  final mainEndingTemp = currentMain + ending;
  if (mainEndingTemp.length > 1) {
    for (final letter in currentMain.split('')) {
      parts.add(letter);
    }
  }

  // 2. Spell ending
  if (ending.isNotEmpty) {
    parts.add(ending);
  }

  // 3. Main + Ending together
  final mainEnding = currentMain + ending;
  if (mainEnding.length > 1) {
    parts.add(mainEnding);
  }

  // 4. Initial + Main_Ending
  String syllableNoTone = "";
  if (initial.isNotEmpty) {
    parts.add(initial);
    parts.add(mainEnding);

    // Fix double-u for "qu"
    String finalMainEnding = mainEnding;
    if (initial == "qu" && ending.isNotEmpty) {
      finalMainEnding = mainEnding.substring(1);
    }

    syllableNoTone = initial + finalMainEnding;
    if (syllableNoTone.isNotEmpty) {
      parts.add(syllableNoTone);
    }
  }

  // 5. Add tone name
  if (tone != "Ngang") {
    parts.add(tone.toLowerCase());
  }

  // 6. Final word with tone
  if (tone != "Ngang") {
    parts.add(word);
  }

  // 7. Single letter (alphabet case)
  if (word.length == 1) parts = [word];

  final spellString = parts.join(' ');

  // 8. Build TTS string
  List<String> ttsParts = List.from(parts);

  for (int idx = 0; idx < ttsParts.length; idx++) {
    String token = ttsParts[idx];

    // Add "ờ" to consonants
    if (INITIALS.contains(token) || ENDINGS.contains(token)) {
      if (token == "k") {
        ttsParts[idx] = "ca";
      } else if (token == "ngh") {
        ttsParts[idx] = "ngờ";
      } else if (token == "gh") {
        ttsParts[idx] = "gờ";
      } else if (token != "gi") {
        ttsParts[idx] = token + "ờ";
      }
    }

    // Special case "i" and "y"
    if ((token == "i" || token == "y") && (ttsParts.length > 1)){
      ttsParts[idx] += ttsParts[idx];
    }

    // Special case "q"
    if (token == "q"){
      ttsParts[idx] = "cu";
    }


    // Add sắc tone to closed syllables
    if ((token == mainEnding || token == syllableNoTone) &&
        ["ch", "c", "p", "t"].contains(ending)) {
      ttsParts[idx] = addTone(ttsParts[idx], "s");
    }

    // Special case: "qu" with stop ending
    if (initial == "qu" && ending.isNotEmpty) {
      if (ttsParts[idx].length > 1 &&
          ttsParts[idx].substring(1) == mainEnding &&
          ["ch", "c", "p", "t"].contains(ending)) {
        ttsParts[idx] = addTone(ttsParts[idx], "s");
      }
    }
  }

  final ttsString = ttsParts.join(' ');

  return DecomposedSyllable(
    initial: initial.isEmpty ? "(none)" : unorm.nfc(initial),
    nucleus: mainNfc.isEmpty ? "(none)" : unorm.nfc(mainNfc),
    ending: ending.isEmpty ? "(none)" : unorm.nfc(ending),
    tone: tone,
    original: unorm.nfc(word),
    spellString: unorm.nfc(spellString),
    ttsString: unorm.nfc(ttsString),
  );
}

/// Get full spelling for a sentence (now uses safer splitting)
DecomposedSyllable getSpellingForText(String text) {
  // Use the same regex style as Python, but more robust for Vietnamese
  final RegExp regex = RegExp(r'[\p{L}\p{N}]+', unicode: true);
  final words = regex
      .allMatches(text)
      .map((m) => m.group(0)!)
      .where((w) => w.trim().isNotEmpty)
      .toList();

  final ttsParts = <String>[];
  final spellParts = <String>[];
  for (final w in words) {
    final result = decomposeVietnameseSyllable(w);
    if (result.ttsString.isNotEmpty) {
      ttsParts.add(result.ttsString);
      ttsParts.add(""); //for a short break between each word.
      spellParts.add(result.spellString);
      spellParts.add(""); //for a short break between each word.
    }
  }
  return DecomposedSyllable(
    initial: "(none)",
    nucleus: "(none)",
    ending: "(none)",
    tone: "(none)",
    original: text,
    spellString: spellParts.join(' '),
    ttsString: ttsParts.join(' '),
  );
}