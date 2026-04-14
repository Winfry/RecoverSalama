"""
ocr_pdf.py — OCR a scanned PDF and save as a text file for ingestion.

Use this for PDFs that extracted 0 chunks because they are image-based
(scanned documents with no text layer).

USAGE:
    pip install pytesseract pdf2image Pillow
    # Also install Tesseract OCR: https://github.com/tesseract-ocr/tesseract
    # On Windows: https://github.com/UB-Mannheim/tesseract/wiki

    python backend/ml/scripts/ocr_pdf.py "food composition.pdf"

OUTPUT:
    Creates "food composition.txt" in the same directory.
    Then re-run build_knowledge_base.py — it will pick up the .txt file.

REQUIREMENTS:
    pytesseract
    pdf2image
    Pillow
    Tesseract OCR installed on the system
"""

import sys
import os
from pathlib import Path

def ocr_pdf(pdf_path: str) -> None:
    try:
        from pdf2image import convert_from_path
        import pytesseract
    except ImportError:
        print("ERROR: Missing dependencies. Run:")
        print("  pip install pytesseract pdf2image Pillow")
        print("  Then install Tesseract OCR from https://github.com/UB-Mannheim/tesseract/wiki")
        sys.exit(1)

    pdf_file = Path(pdf_path)
    if not pdf_file.exists():
        print(f"ERROR: File not found: {pdf_path}")
        sys.exit(1)

    output_file = pdf_file.with_suffix('.txt')
    print(f"OCR processing: {pdf_file.name}")
    print(f"Output: {output_file.name}")

    try:
        pages = convert_from_path(str(pdf_file), dpi=300)
        print(f"Pages: {len(pages)}")
    except Exception as e:
        print(f"ERROR converting PDF to images: {e}")
        print("Make sure poppler is installed:")
        print("  Windows: https://github.com/oschwartz10612/poppler-windows/releases")
        print("  Add poppler/bin to PATH")
        sys.exit(1)

    all_text = []
    for i, page in enumerate(pages, 1):
        if i % 10 == 0:
            print(f"  OCR page {i}/{len(pages)}...")
        try:
            text = pytesseract.image_to_string(page, lang='eng')
            if text.strip():
                all_text.append(f"\n--- Page {i} ---\n{text}")
        except Exception as e:
            print(f"  WARNING: Page {i} OCR failed: {e}")

    if not all_text:
        print("ERROR: No text extracted. Check Tesseract installation.")
        sys.exit(1)

    full_text = "\n".join(all_text)
    output_file.write_text(full_text, encoding='utf-8')
    print(f"\nDone! Extracted {len(full_text):,} characters from {len(all_text)} pages.")
    print(f"Saved to: {output_file}")
    print("\nNext step: Re-run build_knowledge_base.py")
    print("It will automatically pick up the .txt file for embedding.")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        kb_dir = Path(__file__).parent.parent / "data" / "knowledge_base"
        print("Usage: python ocr_pdf.py <pdf_filename>")
        print(f"\nPDFs in knowledge base directory ({kb_dir}):")
        for f in kb_dir.glob("*.pdf"):
            print(f"  {f.name}")
        sys.exit(0)

    # Resolve path — can be just filename or full path
    pdf_arg = sys.argv[1]
    pdf_path = Path(pdf_arg)
    if not pdf_path.is_absolute() and not pdf_path.exists():
        # Try knowledge base directory
        kb_dir = Path(__file__).parent.parent / "data" / "knowledge_base"
        pdf_path = kb_dir / pdf_arg

    ocr_pdf(str(pdf_path))
