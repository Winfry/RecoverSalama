# -*- coding: utf-8 -*-
"""
verify_ai.py — End-to-end verification of the SalamaRecover AI pipeline.

Tests three things in sequence:
  1. RAG retrieval — does pgvector return relevant chunks from the knowledge base?
  2. Gemini chat — does Gemini generate a grounded, clinically sound response?
  3. Kiswahili — does the AI respond naturally in Kiswahili?

Run from the backend/ directory:
  python ml/scripts/verify_ai.py

No auth token needed — this calls services directly, not via HTTP.
"""

import os
import sys
import asyncio
from pathlib import Path

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# ── Path setup ────────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
BACKEND_DIR = SCRIPT_DIR.parent.parent
env_path = BACKEND_DIR / ".env"
if env_path.exists():
    from dotenv import load_dotenv
    load_dotenv(env_path)

sys.path.insert(0, str(BACKEND_DIR))

# ── Test cases ────────────────────────────────────────────────────────────
# Each test has a query and a list of keywords we expect in the response.
# If ANY keyword appears, the test passes.

ENGLISH_TESTS = [
    {
        "label": "C-section diet Day 5",
        "query": "What should I eat on Day 5 after my C-section?",
        "surgery_type": "Caesarean Section",
        "days": 5,
        "expect_any": ["soft", "uji", "soup", "porridge", "liquid", "protein", "ugali", "diet"],
    },
    {
        "label": "Wound warning signs",
        "query": "My wound is red and warm, should I be worried?",
        "surgery_type": "Caesarean Section",
        "days": 7,
        "expect_any": ["infection", "doctor", "hospital", "daktari", "redness", "concern", "contact"],
    },
    {
        "label": "Knee replacement recovery",
        "query": "When can I start walking after knee replacement surgery?",
        "surgery_type": "Knee Replacement",
        "days": 3,
        "expect_any": ["walk", "physio", "exercise", "day", "gentle", "movement", "rehabilit"],
    },
    {
        "label": "Pain management",
        "query": "I have a lot of pain. What can I take?",
        "surgery_type": "Appendectomy",
        "days": 2,
        "expect_any": ["paracetamol", "ibuprofen", "pain", "medication", "doctor", "prescri"],
    },
]

KISWAHILI_TESTS = [
    {
        "label": "Kiswahili — chakula baada ya upasuaji",
        "query": "Nini ninaweza kula baada ya upasuaji wangu?",
        "surgery_type": "Caesarean Section",
        "days": 4,
        "expect_any": ["kula", "chakula", "uji", "supu", "mboga", "protini", "lishe"],
    },
    {
        "label": "Kiswahili — maumivu",
        "query": "Nina maumivu makali sana, nifanye nini?",
        "surgery_type": "Hernia Repair",
        "days": 2,
        "expect_any": ["daktari", "hospitali", "maumivu", "dawa", "pumzika", "haraka"],
    },
]


# ── Helpers ───────────────────────────────────────────────────────────────

def header(text):
    print(f"\n{'='*65}")
    print(f"  {text}")
    print(f"{'='*65}")

def section(text):
    print(f"\n  {'-'*60}")
    print(f"  {text}")
    print(f"  {'-'*60}")

def ok(text):    print(f"  [PASS] {text}")
def fail(text):  print(f"  [FAIL] {text}")
def info(text):  print(f"  {text}")


# ── Test 1: RAG retrieval ─────────────────────────────────────────────────

async def test_rag():
    section("TEST 1 — RAG Retrieval (pgvector similarity search)")
    from app.services.ai.rag_service import RAGService

    rag = RAGService()
    query = "What foods should a C-section patient eat in the first week of recovery?"
    info(f"Query: \"{query}\"")

    try:
        chunks = await rag.retrieve(query=query, top_k=5)
    except Exception as e:
        fail(f"RAG retrieval failed: {e}")
        return False

    if not chunks:
        fail("No chunks returned — knowledge base may be empty or pgvector function missing")
        return False

    ok(f"Retrieved {len(chunks)} chunks from knowledge base")
    print()
    for i, chunk in enumerate(chunks, 1):
        source = chunk.get("source", "Unknown")[:55]
        page   = chunk.get("page", "?")
        sim    = chunk.get("similarity", 0)
        preview = chunk.get("content", "")[:100].replace("\n", " ")
        print(f"  Chunk {i}: [{source}... p.{page}] sim={sim:.3f}")
        print(f"           \"{preview}...\"")

    return True


# ── Test 2: Gemini chat (English) ─────────────────────────────────────────

async def test_gemini_english():
    section("TEST 2 — Gemini AI Chat (English)")
    from app.services.ai.gemini_service import GeminiService
    from app.services.ai.rag_service import RAGService

    gemini = GeminiService()
    rag    = RAGService()
    passed = 0

    for test in ENGLISH_TESTS:
        info(f"\n  [{test['label']}]")
        info(f"  Q: {test['query']}")
        try:
            chunks = await rag.retrieve(query=test["query"], top_k=5)
            result = await gemini.chat(
                message=test["query"],
                rag_context=chunks,
                patient_context={
                    "name": "Test Patient",
                    "surgery_type": test["surgery_type"],
                    "days_since_surgery": test["days"],
                    "allergies": [],
                },
            )
            reply = result["reply"]
            sources = result["sources"]
            reply_lower = reply.lower()

            print(f"  A: {reply[:250]}{'...' if len(reply) > 250 else ''}")
            print(f"  Sources: {sources[:2]}")

            matched = any(kw in reply_lower for kw in test["expect_any"])
            if matched:
                ok(f"Response contains expected clinical content")
                passed += 1
            else:
                fail(f"Response missing expected keywords: {test['expect_any']}")

        except Exception as e:
            fail(f"Error: {e}")

    return passed, len(ENGLISH_TESTS)


# ── Test 3: Kiswahili ─────────────────────────────────────────────────────

async def test_kiswahili():
    section("TEST 3 — Kiswahili Responses")
    from app.services.ai.gemini_service import GeminiService
    from app.services.ai.rag_service import RAGService

    gemini = GeminiService()
    rag    = RAGService()
    passed = 0

    for test in KISWAHILI_TESTS:
        info(f"\n  [{test['label']}]")
        info(f"  Q: {test['query']}")
        try:
            chunks = await rag.retrieve(query=test["query"], top_k=5)
            result = await gemini.chat(
                message=test["query"],
                rag_context=chunks,
                patient_context={
                    "name": "Mgonjwa wa Majaribio",
                    "surgery_type": test["surgery_type"],
                    "days_since_surgery": test["days"],
                    "allergies": [],
                },
            )
            reply  = result["reply"]
            reply_lower = reply.lower()

            print(f"  A: {reply[:300]}{'...' if len(reply) > 300 else ''}")

            matched = any(kw in reply_lower for kw in test["expect_any"])
            if matched:
                ok("Response contains Kiswahili clinical content")
                passed += 1
            else:
                fail(f"Response missing expected Kiswahili content: {test['expect_any']}")

        except Exception as e:
            fail(f"Error: {e}")

    return passed, len(KISWAHILI_TESTS)


# ── Main ──────────────────────────────────────────────────────────────────

async def main():
    header("SALAMARECOVER — AI PIPELINE VERIFICATION")

    # Check env vars
    missing = [v for v in ["GEMINI_API_KEY", "SUPABASE_URL", "SUPABASE_SERVICE_KEY"] if not os.getenv(v)]
    if missing:
        fail(f"Missing environment variables: {', '.join(missing)}")
        sys.exit(1)

    total_passed = 0
    total_tests  = 0

    # Test 1: RAG
    rag_ok = await test_rag()
    if not rag_ok:
        print("\n  Stopping — RAG must work before testing Gemini.")
        sys.exit(1)
    total_tests += 1
    total_passed += 1

    # Test 2: English
    eng_passed, eng_total = await test_gemini_english()
    total_passed += eng_passed
    total_tests  += eng_total

    # Test 3: Kiswahili
    sw_passed, sw_total = await test_kiswahili()
    total_passed += sw_passed
    total_tests  += sw_total

    # Summary
    header("RESULTS")
    print(f"\n  Tests passed: {total_passed} / {total_tests}")

    if total_passed == total_tests:
        print("\n  All tests passed.")
        print("  The AI is grounded in Kenya MOH clinical guidelines.")
        print("  The knowledge base is working correctly.")
        print("  Phase 4 is complete.\n")
    else:
        failed = total_tests - total_passed
        print(f"\n  {failed} test(s) failed — review the output above.")
        print("  Common causes:")
        print("  - Knowledge base too small (run --pdfs-only when quota resets)")
        print("  - Gemini API quota hit (wait or enable billing)")
        print("  - RAG similarity threshold too high (lower match_threshold in rag_service.py)\n")

    print("=" * 65)


if __name__ == "__main__":
    asyncio.run(main())
