import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Vietnamese syllable decomposition results.
class DecomposedSyllable {
  final String initial;
  final String nucleus;
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

/// Constants for Vietnamese decomposition.
const List<String> INITIALS = [
  "ngh", "ng", "gh", "gi", "qu", "ch", "kh", "nh", "ph", "th", "tr",
  "b", "c", "d", "đ", "g", "h", "k", "l", "m", "n", "p", "q", "r",
  "s", "t", "v", "x",
];

const List<String> ENDINGS = ["ch", "nh", "ng", "c", "m", "n", "p", "t"];

const Map<String, Map<String, String>> GI_SPECIAL_CASES = {
  "gì": {
    "initial": "gi", "nucleus": "", "ending": "", "tone": "Huyền",
    "spell": "gi huyền gì", "tts": "gi huyền gì",
  },
  "gìn": {
    "initial": "gi", "nucleus": "in", "ending": "", "tone": "Huyền",
    "spell": "gi in gin huyền gìn", "tts": "gi in gin huyền gìn",
  },
  "giếng": {
    "initial": "gi", "nucleus": "iêng", "ending": "", "tone": "Sắc",
    "spell": "gi iêng giêng sắc giếng", "tts": "gi iêng giêng sắc giếng",
  },
  "giềng": {
    "initial": "gi", "nucleus": "iêng", "ending": "", "tone": "Huyền",
    "spell": "gi iêng giêng huyền giềng", "tts": "gi iêng giêng huyền giềng",
  },
  "giết": {
    "initial": "gi", "nucleus": "iết", "ending": "", "tone": "Sắc",
    "spell": "gi iết giết sắc giết", "tts": "gi iết giết sắc giết",
  },
  "giêng": {
    "initial": "gi", "nucleus": "iêng", "ending": "", "tone": "Ngang",
    "spell": "gi iêng giêng", "tts": "gi iêng giêng",
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

/// Add Vietnamese tone mark to a syllable.
String addTone(String syllable, String toneCode) {
  if (syllable.isEmpty || toneCode == "" || toneCode == "0") return syllable;

  const toneSymbols = {
    "s": "\u0301", // sắc
    "f": "\u0300", // huyền
    "r": "\u0323", // nặng
    "x": "\u0309", // hỏi
    "j": "\u0303", // ngã
  };

  final combining = toneSymbols[toneCode.toLowerCase()] ?? "";
  if (combining == "") return syllable;

  // Find best vowel position
  int bestPos = -1;
  int bestPriority = VOWEL_ORDER.length;

  for (int i = 0; i < syllable.length; i++) {
    final char = syllable[i].toLowerCase();
    final priority = VOWEL_ORDER.indexOf(char);
    if (priority != -1 && priority < bestPriority) {
      bestPriority = priority;
      bestPos = i;
    }
  }

  if (bestPos == -1) return syllable;

  return syllable.substring(0, bestPos + 1) + combining + syllable.substring(bestPos + 1);
}

/// Decompose a Vietnamese syllable.
DecomposedSyllable decomposeVietnameseSyllable(String word) {
  final lowerWord = word.toLowerCase();

  // Special cases
  if (GI_SPECIAL_CASES.containsKey(lowerWord)) {
    final sp = GI_SPECIAL_CASES[lowerWord]!;
    return DecomposedSyllable(
      initial: sp["initial"]!,
      nucleus: sp["nucleus"]!.isEmpty ? "(none)" : sp["nucleus"]!,
      ending: sp["ending"]!.isEmpty ? "(none)" : sp["ending"]!,
      tone: sp["tone"]!,
      original: word,
      spellString: sp["spell"]!,
      ttsString: sp["tts"]!,
    );
  }

  // Normalize and extract tone
  final normalized = unorm.nfd(lowerWord);
  String toneName = "Ngang";
  for (final char in normalized.split('')) {
    if (TONE_MAP.containsKey(char)) {
      toneName = TONE_MAP[char]!;
      break;
    }
  }

  // Base form without tone
  final baseStr = normalized.split('').where((c) => !TONE_MAP.containsKey(c)).join();
  final chars = baseStr.split('');

  // Initial consonant
  String initial = "";
  int startIndex = 0;
  final sortedInitials = List<String>.from(INITIALS)..sort((a, b) => b.length.compareTo(a.length));
  
  for (final init in sortedInitials) {
    if (chars.length >= init.length && chars.sublist(0, init.length).join() == init) {
      initial = init;
      startIndex = init.length;
      break;
    }
  }

  List<String> remaining = chars.sublist(startIndex);

  // Ending consonant
  String ending = "";
  final sortedEndings = List<String>.from(ENDINGS)..sort((a, b) => b.length.compareTo(a.length));
  
  if (remaining.isNotEmpty) {
    for (final end in sortedEndings) {
      if (remaining.length >= end.length && remaining.sublist(remaining.length - end.length).join() == end) {
        ending = end;
        remaining = remaining.sublist(0, remaining.length - end.length);
        break;
      }
    }
  }

  // Nucleus
  String nucleus = remaining.join();
  String nucleusNfc = unorm.nfc(nucleus);

  // Build spelling string
  List<String> parts = [];
  
  // Handle "qu" special case
  if (initial == "qu" && ending.isNotEmpty) {
    nucleusNfc = "u" + nucleusNfc;
  }

  // 1. Spell nucleus
  if ((nucleusNfc + ending).length > 1) {
    for (final char in nucleusNfc.split('')) {
      parts.add(char);
    }
  }

  // 2. Spell ending
  if (ending.isNotEmpty) {
    parts.add(ending);
  }

  // 3. Main + Ending together
  String mainEnding = nucleusNfc + ending;
  if (mainEnding.length > 1) {
    parts.add(mainEnding);
  }

  // 4. Initial + Main_Ending
  String syllableNoTone = "";
  if (initial.isNotEmpty) {
    parts.add(initial);
    parts.add(mainEnding);

    if (initial == "qu" && ending.isNotEmpty) {
      mainEnding = mainEnding.substring(1);
    }

    syllableNoTone = initial + mainEnding;
    if (syllableNoTone.isNotEmpty) {
      parts.add(syllableNoTone);
    }

    // 5. Add tone
    if (toneName != "Ngang") {
      parts.add(toneName.toLowerCase());
    }

    // 6. Word with tone
    if (toneName != "Ngang") {
      parts.add(word);
    }
  }

  final spellString = parts.join(' ');

  // Build TTS string
  List<String> ttsParts = List.from(parts);
  for (int i = 0; i < ttsParts.length; i++) {
    String token = ttsParts[i];

    // Add 'ờ' for consonants
    if (INITIALS.contains(token) || ENDINGS.contains(token)) {
      if (token == "k") {
        ttsParts[i] = "ca";
      } else if (token == "ngh") {
        ttsParts[i] = "ngờ";
      } else if (token == "gh") {
        ttsParts[i] = "gờ";
      } else if (token != "gi") {
        ttsParts[i] = token + "ờ";
      }
    }

    // Stop consonants adjustment
    final stopConsonants = ["ch", "c", "p", "t"];
    if ((token == mainEnding || token == syllableNoTone) && stopConsonants.contains(ending)) {
      ttsParts[i] = addTone(ttsParts[i], "s");
    }

    // Special qu + stop
    if (initial == "qu" && ending.isNotEmpty) {
       if (token.length > 1 && token.substring(1) == mainEnding && stopConsonants.contains(ending)) {
         ttsParts[i] = addTone(ttsParts[i], "s");
       }
    }
  }

  return DecomposedSyllable(
    initial: unorm.nfc(initial.isEmpty ? "(none)" : initial),
    nucleus: unorm.nfc(nucleusNfc.isEmpty ? "(none)" : nucleusNfc),
    ending: unorm.nfc(ending.isEmpty ? "(none)" : ending),
    tone: toneName,
    original: unorm.nfc(word),
    spellString: unorm.nfc(spellString),
    ttsString: unorm.nfc(ttsParts.join(' ')),
  );
}

String getSpellingForText(String text) {
  final words = RegExp(r"[\w]+", unicode: true).allMatches(text).map((m) => m.group(0)!).toList();
  List<String> ttsStrings = [];
  for (final w in words) {
    final result = decomposeVietnameseSyllable(w);
    if (result.ttsString.isNotEmpty) {
      ttsStrings.add(result.ttsString);
    }
  }
  return ttsStrings.join(". ");
}
