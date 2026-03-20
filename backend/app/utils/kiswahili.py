"""
Kiswahili language utilities.

Detects whether patient input is in English or Kiswahili
so the AI can respond in the same language.
"""

# Common Kiswahili words used in health context
KISWAHILI_MARKERS = {
    "habari", "nzuri", "maumivu", "daktari", "hospitali",
    "upasuaji", "kupona", "dalili", "homa", "kichefuchefu",
    "chakula", "mlo", "ugali", "uji", "maziwa", "mayai",
    "ndizi", "sukuma", "wiki", "samaki", "maharagwe", "kuku",
    "maji", "chai", "supu", "dawa", "kidonda", "haraka",
    "msaada", "asante", "tafadhali", "ndiyo", "hapana",
    "leo", "jana", "kesho", "siku", "usiku", "asubuhi",
    "ninajisikia", "sawa", "vizuri", "vibaya", "pole",
}


def detect_language(text: str) -> str:
    """
    Detect if text is Kiswahili or English.
    Returns 'sw' for Kiswahili, 'en' for English.
    """
    words = set(text.lower().split())
    sw_count = len(words & KISWAHILI_MARKERS)

    # If 20%+ of words are Kiswahili, classify as Kiswahili
    if len(words) > 0 and sw_count / len(words) >= 0.2:
        return "sw"

    return "en"
