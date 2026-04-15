"""
verify_channels.py — Test WhatsApp and USSD webhooks end-to-end.

Run with backend running:
    python ml/scripts/verify_channels.py

Or against a deployed URL:
    python ml/scripts/verify_channels.py --url https://your-app.onrender.com
"""

import sys
import argparse
import httpx

def test_ussd(base_url: str) -> None:
    url = f"{base_url}/api/webhooks/ussd"
    phone = "+254712345678"
    session = "verify-test-001"

    tests = [
        ("Main menu",          ""),
        ("Check-in branch",    "1"),
        ("Pain question",      "1"),
        ("Symptom question",   "1*3"),
        ("LOW result",         "1*3*5"),
        ("EMERGENCY result",   "1*1*1"),   # pain=max, symptom=fever
        ("HIGH result",        "1*4*4"),   # pain=makali, symptom=swelling
        ("Diet branch",        "2"),
        ("Diet day 1-2",       "2*1"),
        ("Diet day 8+",        "2*4"),
        ("Emergency numbers",  "3"),
        ("Help",               "4"),
    ]

    print("\n" + "="*60)
    print("USSD TESTS")
    print("="*60)

    passed = 0
    failed = 0

    for name, text in tests:
        try:
            r = httpx.post(url, data={
                "sessionId": session,
                "phoneNumber": phone,
                "text": text,
            }, timeout=10)

            body = r.text.strip()
            # USSD responses are returned as a JSON string — strip the quotes
            # e.g. '"CON Karibu..."' → 'CON Karibu...'
            if body.startswith('"') and body.endswith('"'):
                body = body[1:-1]
            starts_con = body.startswith("CON")
            starts_end = body.startswith("END")
            ok = r.status_code == 200 and (starts_con or starts_end)

            status = "✓ PASS" if ok else "✗ FAIL"
            prefix = "CON" if starts_con else "END" if starts_end else "???"
            first_line = body.split("\n")[0][:50]

            print(f"  {status}  [{name}]  text='{text}'")
            print(f"         → {prefix}: {first_line}")

            if ok:
                passed += 1
            else:
                failed += 1
                print(f"         HTTP {r.status_code}: {body[:100]}")

        except Exception as e:
            print(f"  ✗ FAIL  [{name}]  ERROR: {e}")
            failed += 1

    print(f"\n  USSD: {passed} passed, {failed} failed")
    return passed, failed


def test_whatsapp(base_url: str) -> None:
    url = f"{base_url}/api/webhooks/whatsapp"
    phone = "+254712345678"

    tests = [
        ("Check-in keyword (EN)",    "check in today"),
        ("Check-in keyword (SW)",    "maumivu yangu"),
        ("Diet keyword (SW)",        "chakula gani leo"),
        ("Help keyword",             "msaada"),
        ("Emergency keyword",        "dharura"),
        ("Free text (AI)",           "Nina maumivu kidogo siku ya tatu"),
        ("Kiswahili question",       "Ninaweza kula nini baada ya upasuaji?"),
        ("Default fallback",         "hello"),
    ]

    print("\n" + "="*60)
    print("WHATSAPP TESTS")
    print("="*60)

    passed = 0
    failed = 0

    for name, message in tests:
        try:
            r = httpx.post(url, data={
                "from": phone,
                "text": message,
            }, timeout=30)  # longer timeout for Gemini

            body = r.text.strip()
            ok = r.status_code == 200 and len(body) > 10

            status = "✓ PASS" if ok else "✗ FAIL"
            # Show first 80 chars of response
            preview = body[:80].replace("\n", " ")

            print(f"  {status}  [{name}]")
            print(f"         msg: '{message}'")
            print(f"         → '{preview}...'")

            if ok:
                passed += 1
            else:
                failed += 1
                print(f"         HTTP {r.status_code}")

        except Exception as e:
            print(f"  ✗ FAIL  [{name}]  ERROR: {e}")
            failed += 1

    print(f"\n  WhatsApp: {passed} passed, {failed} failed")
    return passed, failed


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--url",
        default="http://localhost:8000",
        help="Base URL of the backend (default: http://localhost:8000)",
    )
    parser.add_argument("--ussd-only", action="store_true")
    parser.add_argument("--whatsapp-only", action="store_true")
    args = parser.parse_args()

    base_url = args.url.rstrip("/")
    print(f"\nTesting channels at: {base_url}")

    # Health check first
    try:
        r = httpx.get(f"{base_url}/health", timeout=5)
        if r.status_code == 200:
            print("✓ Backend is running")
        else:
            print(f"✗ Backend health check failed: HTTP {r.status_code}")
            sys.exit(1)
    except Exception as e:
        print(f"✗ Cannot reach backend at {base_url}: {e}")
        print("  Make sure the backend is running: uvicorn app.main:app --port 8000")
        sys.exit(1)

    total_passed = 0
    total_failed = 0

    if not args.whatsapp_only:
        p, f = test_ussd(base_url)
        total_passed += p
        total_failed += f

    if not args.ussd_only:
        p, f = test_whatsapp(base_url)
        total_passed += p
        total_failed += f

    print("\n" + "="*60)
    print(f"TOTAL: {total_passed} passed, {total_failed} failed")
    print("="*60)

    if total_failed > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
