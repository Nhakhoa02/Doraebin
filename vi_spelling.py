"""
Vietnamese syllable decomposition and spelling string generator.

Provides functions to decompose Vietnamese syllables into components
(initial, nucleus, ending, tone) and generate "spelling song" strings
for TTS pronunciation.
"""

import unicodedata


def add_tone(syllable: str, tone: str) -> str:
    """
    Add Vietnamese tone mark to a syllable.

    Args:
        syllable: Base syllable without tone (e.g. "oc")
        tone: Tone code — 's' (sắc), 'f' (huyền), 'r' (nặng),
              'x' (hỏi), 'j' (ngã)

    Returns:
        Syllable with tone mark applied (e.g. "óc")
    """
    if not syllable or tone in (None, "", "0"):
        return syllable

    tone_map = {
        "s": "\u0301",  # sắc   (acute)
        "f": "\u0300",  # huyền (grave)
        "r": "\u0323",  # nặng  (dot below)
        "x": "\u0309",  # hỏi   (hook above)
        "j": "\u0303",  # ngã   (tilde)
    }

    combining = tone_map.get(tone.lower(), "")
    vowel_order = "aăâeêoôơiuưy"

    # Find best vowel position for tone placement
    best_pos = -1
    best_priority = len(vowel_order)

    for i, ch in enumerate(syllable):
        lower = ch.lower()
        if lower in vowel_order:
            priority = vowel_order.index(lower)
            if priority < best_priority:
                best_priority = priority
                best_pos = i

    if best_pos == -1:
        return syllable  # no vowel found

    return syllable[: best_pos + 1] + combining + syllable[best_pos + 1 :]


# Consonant lists used by the decomposer
INITIALS = [
    "ngh", "ng", "gh", "gi", "qu", "ch", "kh", "nh", "ph", "th", "tr",
    "b", "c", "d", "đ", "g", "h", "k", "l", "m", "n", "p", "q", "r",
    "s", "t", "v", "x",
]

ENDINGS = ["ch", "nh", "ng", "c", "m", "n", "p", "t"]

# Special cases for "gi" — common exceptions in Vietnamese primary schools
_GI_SPECIAL_CASES = {
    "gì": {
        "initial": "gi", "main": "", "ending": "", "tone": "Huyền",
        "spell": "gi huyền gì", "tts": "gi huyền gì",
    },
    "gìn": {
        "initial": "gi", "main": "in", "ending": "", "tone": "Huyền",
        "spell": "gi in gin huyền gìn", "tts": "gi in gin huyền gìn",
    },
    "giếng": {
        "initial": "gi", "main": "iêng", "ending": "", "tone": "Sắc",
        "spell": "gi iêng giêng sắc giếng", "tts": "gi iêng giêng sắc giếng",
    },
    "giềng": {
        "initial": "gi", "main": "iêng", "ending": "", "tone": "Huyền",
        "spell": "gi iêng giêng huyền giềng", "tts": "gi iêng giêng huyền giềng",
    },
    "giết": {
        "initial": "gi", "main": "iết", "ending": "", "tone": "Sắc",
        "spell": "gi iết giết sắc giết", "tts": "gi iết giết sắc giết",
    },
    "giêng": {
        "initial": "gi", "main": "iêng", "ending": "", "tone": "Ngang",
        "spell": "gi iêng giêng", "tts": "gi iêng giêng",
    },
}


def decompose_vietnamese_syllable(word: str) -> dict:
    """
    Decompose a Vietnamese syllable into its components and build
    spelling / TTS strings.

    Args:
        word: A single Vietnamese word/syllable.

    Returns:
        Dict with keys: initial, main, ending, tone, original,
        spell_string, tts_string
    """
    if not word:
        return {
            "initial": "", "main": "", "ending": "", "tone": "Ngang",
            "original": word, "spell_string": "", "tts_string": "",
        }

    # --- Check special cases first ---
    if word.lower() in _GI_SPECIAL_CASES:
        sp = _GI_SPECIAL_CASES[word.lower()]
        return {
            "initial": sp["initial"],
            "main": sp["main"] or "(none)",
            "ending": sp["ending"] or "(none)",
            "tone": sp["tone"],
            "original": word,
            "spell_string": sp["spell"],
            "tts_string": sp["tts"],
        }

    # --- Normalize to NFD and extract tone ---
    normalized = unicodedata.normalize("NFD", word.lower())

    tone_map = {
        "\u0300": "Huyền",
        "\u0309": "Hỏi",
        "\u0303": "Ngã",
        "\u0301": "Sắc",
        "\u0323": "Nặng",
    }

    tone = "Ngang"
    for char in normalized:
        if char in tone_map:
            tone = tone_map[char]
            break

    # Remove tone marks to get the base form
    base = "".join(ch for ch in normalized if ch not in tone_map)

    # --- Find initial consonant ---
    chars = list(base)
    initial = ""
    i = 0
    for init in sorted(INITIALS, key=len, reverse=True):
        if "".join(chars[: len(init)]) == init:
            initial = init
            i = len(init)
            break

    remaining = chars[i:]

    # --- Find ending consonant ---
    ending = ""
    if remaining:
        for end in sorted(ENDINGS, key=len, reverse=True):
            if "".join(remaining[-len(end) :]) == end:
                ending = end
                remaining = remaining[: -len(end)]
                break

    # --- Nucleus (main vowel) ---
    main = "".join(remaining)
    main_nfc = unicodedata.normalize("NFC", main)

    # --- Build spelling string ---
    parts = []

    # Handle "qu" special case
    if initial == "qu" and ending:
        main_nfc = "u" + main_nfc

    # 1. Spell main vowel letter by letter
    if len(main_nfc + ending) > 1:
        for letter in main_nfc:
            parts.append(letter)

    # 2. Spell ending
    if ending:
        parts.append(ending)

    # 3. Main + Ending together
    main_ending = main_nfc + ending
    if len(main_ending) > 1:
        parts.append(main_ending)

    # 4. Initial + Main_Ending
    syllable_no_tone = ""
    if initial:
        parts.append(initial)
        parts.append(main_ending)

        # Fix double-u for "qu"
        if initial == "qu" and ending:
            main_ending = main_ending[1:]

        syllable_no_tone = initial + main_ending
        if syllable_no_tone:
            parts.append(syllable_no_tone)

        # 5. Add tone name
        if tone != "Ngang":
            parts.append(tone.lower())

        # 6. Final word with tone
        if tone != "Ngang":
            parts.append(word)

    spell_string = " ".join(parts)

    # --- Build TTS-friendly string ---
    tts_parts = list(parts)  # copy
    for idx in range(len(tts_parts)):
        token = tts_parts[idx]

        # Add "ờ" to consonant clusters so TTS can pronounce them
        if token in INITIALS or token in ENDINGS:
            if token == "k":
                tts_parts[idx] = "ca"
            elif token == "ngh":
                tts_parts[idx] = "ngờ"
            elif token == "gh":
                tts_parts[idx] = "gờ"
            elif token != "gi":
                tts_parts[idx] = token + "ờ"

        # Add sắc tone to closed syllables ending in stop consonants
        if (token == main_ending or token == syllable_no_tone) and ending in [
            "ch", "c", "p", "t",
        ]:
            tts_parts[idx] = add_tone(tts_parts[idx], "s")

        # Special case: "qu" with stop ending
        if initial == "qu" and ending:
            if (
                len(tts_parts[idx]) > 1
                and tts_parts[idx][1:] == main_ending
                and ending in ["ch", "c", "p", "t"]
            ):
                tts_parts[idx] = add_tone(tts_parts[idx], "s")

    tts_string = " ".join(tts_parts)

    return {
        "initial": initial or "(none)",
        "main": main_nfc or "(none)",
        "ending": ending or "(none)",
        "tone": tone,
        "original": word,
        "spell_string": spell_string,
        "tts_string": tts_string,
    }


def get_spelling_for_text(text: str) -> str:
    """
    Generate a full TTS-readable spelling string for a Vietnamese sentence.

    Splits the text into words, decomposes each, and joins their
    tts_string values with pauses (periods).

    Args:
        text: Vietnamese sentence.

    Returns:
        TTS-friendly spelling string for the whole sentence.
    """
    import re

    words = re.findall(r"[\w]+", text, re.UNICODE)
    tts_parts = []
    for w in words:
        result = decompose_vietnamese_syllable(w)
        if result["tts_string"]:
            tts_parts.append(result["tts_string"])
    return ". ".join(tts_parts)