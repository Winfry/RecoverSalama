# -*- coding: utf-8 -*-
"""
build_knowledge_base.py — Populate the RAG Knowledge Base for SalamaRecover.

This script processes two data sources and embeds them into Supabase pgvector:

  SOURCE 1 — Surgery Reference Data (15 surgeries)
  ─────────────────────────────────────────────────
  Clinical protocols for every surgery type in the app, including:
  - Surgery overview and Kenya-specific context
  - Indications and procedure description
  - Post-surgical complications (used by risk scorer)
  - Pre-op and post-op diet protocols with KENYAN FOOD NAMES
  - Key nutrients per surgery
  - Evidence base (Lancet, JAMA, Annals of African Surgery, etc.)
  Each surgery generates 6 richly-worded chunks for high-quality retrieval.

  SOURCE 2 — Clinical PDFs (Kenya MOH guidelines)
  ────────────────────────────────────────────────
  - Kenya National Clinical Nutrition & Dietetics Manual (2010)
  - Clinical Guidelines Volume III
  - Food Composition Data for Kenyan Foods
  - National Guidelines on Quality Obstetrics & Perinatal Care
  - Clinical Nutrition Manual Sample

  WHY TWO SOURCES?
  The surgery_reference data gives surgery-specific protocols with
  Kenyan food names. The PDFs provide deep nutritional science,
  food composition tables, and MOH clinical authority.
  Together they make the AI both clinically accurate and locally relevant.

USAGE:
  From project root:
    python backend/ml/scripts/build_knowledge_base.py

  From backend/ directory:
    python ml/scripts/build_knowledge_base.py

  Force re-embed a specific source (skip idempotency check):
    python backend/ml/scripts/build_knowledge_base.py --force

IDEMPOTENCY:
  Safe to run multiple times. Each source is checked before processing —
  if chunks already exist in the DB for that source, it is skipped.
  Use --force to re-embed everything from scratch.
"""

import os
import sys
import re
import time
import json
import argparse
from pathlib import Path

# Force UTF-8 output on Windows terminals
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

# ─────────────────────────────────────────────────────────────────────────────
# PATH SETUP — find .env regardless of where script is called from
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR = Path(__file__).resolve().parent          # backend/ml/scripts/
BACKEND_DIR = SCRIPT_DIR.parent.parent                # backend/
KB_DATA_DIR = SCRIPT_DIR.parent / "data" / "knowledge_base"  # backend/ml/data/knowledge_base/

# Load .env from backend/ directory
env_path = BACKEND_DIR / ".env"
if env_path.exists():
    from dotenv import load_dotenv
    load_dotenv(env_path)
    print(f"Loaded .env from {env_path}")
else:
    print(f"WARNING: No .env found at {env_path}. Using environment variables.")

from google import genai
from google.genai import types as genai_types
from supabase import create_client


# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

EMBEDDING_MODEL = "models/gemini-embedding-001"
EMBEDDING_DIMENSIONS = 768  # Matches VECTOR(768) in Supabase schema
CHUNK_SIZE = 1200       # Larger chunks = fewer API calls = stay within daily quota
CHUNK_OVERLAP = 150     # Character overlap to prevent sentence truncation
EMBED_BATCH_SIZE = 10   # Embed 10 chunks per API call (10x fewer calls vs 1-by-1)
RATE_LIMIT_SLEEP = 13   # Seconds between batch calls — stays under 5 RPM free tier
MAX_RETRIES = 3         # Retry 429 errors up to 3 times with delay from response


# ─────────────────────────────────────────────────────────────────────────────
# PDF DOCUMENT MANIFEST
# ─────────────────────────────────────────────────────────────────────────────

PDF_SOURCES = [
    {
        "filename": "Kenya_National_Clinical_Nutrition_and_Dietetics_Reference_Manual_-_February_2010 (1).pdf",
        "source": "Kenya National Clinical Nutrition & Dietetics Reference Manual (MOH 2010)",
        "category": "nutrition",
        "authority": "Kenya Ministry of Health",
        "priority": 1,  # Process first — most important
    },
    {
        "filename": "food composition.pdf",
        "source": "Food Composition Tables for Kenya — Nutritional Values of Local Foods",
        "category": "food_composition",
        "authority": "Kenya Ministry of Health",
        "priority": 2,  # Critical for meal planning with Kenyan foods
    },
    {
        "filename": "Clinical_Guidelines_Vol_III_Final.pdf",
        "source": "Kenya Clinical Guidelines Volume III (MOH Clinical Standards)",
        "category": "clinical_guidelines",
        "authority": "Kenya Ministry of Health",
        "priority": 3,
    },
    {
        "filename": "NATIONAL GUIDELINES ON QUALITY OBSTETRICS AND PERINATAL CARE_Final June 21 (1).pdf",
        "source": "Kenya National Guidelines on Quality Obstetrics & Perinatal Care (MOH)",
        "category": "obstetrics",
        "authority": "Kenya Ministry of Health",
        "priority": 4,
    },
    {
        "filename": "Clinical-Nutrition-Manual-SOFTY-COPY-SAMPLE.pdf",
        "source": "Kenya Clinical Nutrition Manual — Practical Guide for Health Workers",
        "category": "nutrition",
        "authority": "Kenya Ministry of Health",
        "priority": 5,
    },
]


# ─────────────────────────────────────────────────────────────────────────────
# SURGERY REFERENCE DATA — 15 SURGERIES
# All text is written as natural language for optimal RAG retrieval.
# Each surgery produces 6 chunks: overview, procedure, complications,
# pre-op diet, post-op diet, and key nutrients + research.
# ─────────────────────────────────────────────────────────────────────────────

SURGERY_DATA = [
    {
        "name": "Caesarean Section",
        "code": "C-SECTION",
        "specialty": "Obstetrics",

        "overview": """CAESAREAN SECTION (C-SECTION) — OVERVIEW AND KENYA CONTEXT

A Caesarean section (C-section) is a surgical delivery of a baby through incisions in the abdominal wall and uterus. It is the world's most performed major surgery and in Kenya it is the single most common major operation. Global C-section rates have risen from 6% in 1990 to over 21% in 2018.

In Kenya, C-sections are performed at virtually every level of the health system — from county referral hospitals to Kenyatta National Hospital (KNH), Nairobi Hospital, Aga Khan University Hospital, and Mama Lucy Kibaki Hospital.

WHEN IS A C-SECTION PERFORMED?
A C-section is indicated when vaginal delivery would be unsafe. Common reasons include:
- Labour dystocia (failure to progress in labour)
- Foetal distress or non-reassuring CTG (baby's heart rate abnormal)
- Malpresentation (breech position, transverse lie)
- Placenta praevia or placenta accreta (placenta blocking birth canal)
- Prior uterine surgery (previous C-section scar)
- Eclampsia or severe pre-eclampsia (dangerous blood pressure in pregnancy)
- Cord prolapse (umbilical cord coming out first — emergency)

RECOVERY TIMELINE:
- Hospital stay: 3-5 days (Kenyan public hospitals), 2-3 days (private)
- Return to light activity: Day 7-14
- Full recovery: 6-8 weeks
- Wound care: Keep incision dry for 48-72 hours. Watch for redness, swelling, discharge.""",

        "procedure": """CAESAREAN SECTION — SURGICAL PROCEDURE

ANAESTHESIA: Spinal anaesthesia (injection in lower back) is the gold standard for C-sections. It numbs the lower body while the mother remains awake. General anaesthesia (GA) is reserved for emergencies where spinal is contraindicated or time does not permit.

SURGICAL STEPS:
1. Pfannenstiel (bikini line) or midline skin incision — Pfannenstiel is preferred as it heals better
2. Rectus sheath incision — cutting through the fascial layer
3. Bladder flap — the bladder is gently pushed down to protect it
4. Lower-segment uterine incision — a transverse cut in the lower uterus
5. Baby delivery — the baby is gently guided out, cord clamped and cut
6. Placenta delivery — the placenta and membranes are removed
7. Uterine closure — in 1-2 layers with absorbable sutures
8. Layered abdominal closure — fascia, subcutaneous tissue, skin (staples or sutures)

Duration: 30-60 minutes for uncomplicated C-section. Emergency cases may be completed in 15 minutes.

WHAT TO EXPECT AFTER SURGERY:
- A urinary catheter is placed before surgery (removed Day 1)
- IV drip for fluids and medications (removed when eating well)
- Wound dressing for 48-72 hours
- Moderate incision pain for 3-5 days — managed with paracetamol, ibuprofen, tramadol as needed
- Uterine cramps (afterpains) especially during breastfeeding — normal and expected""",

        "complications": """CAESAREAN SECTION — COMPLICATIONS AND WARNING SIGNS

Knowing the complications of a C-section helps patients and caregivers recognise warning signs early.

SERIOUS COMPLICATIONS (GO TO HOSPITAL IMMEDIATELY):
- Haemorrhage: Excessive bleeding is the leading cause of severe maternal morbidity after C-section. Signs: soaking through pads, dizziness, weakness, rapid heartbeat. Call 999/112 immediately.
- Wound infection / endometritis: Fever above 38°C, increasing wound pain, redness, swelling, discharge from incision, or foul-smelling lochia (postpartum bleeding). Risk highest Day 3-7 post-surgery.
- DVT (Deep Vein Thrombosis): Pain, swelling, warmth in one leg. Can progress to life-threatening pulmonary embolism (chest pain, difficulty breathing).
- Pulmonary embolism: Sudden chest pain, rapid breathing, coughing blood. EMERGENCY — call 999/112.
- Bowel obstruction: Severe abdominal pain, no bowel movements after Day 3, vomiting. Risk is 2.92 times higher after C-section compared to vaginal birth.
- Urinary tract infection: Painful or burning urination, frequency, lower abdominal pain.
- Incisional hernia: Bulge near the wound (can develop weeks to months later).
- Placenta accreta in future pregnancies: Serious risk with each subsequent C-section.

NORMAL SYMPTOMS (NOT DANGEROUS):
- Wound itching as it heals — normal, do not scratch
- Mild swelling at incision edges — normal if no redness or discharge
- Fatigue for 2-4 weeks — normal, rest is important
- Gas pains (trapped wind after surgery) — walk gently, avoid carbonated drinks
- Numbness around the scar — can persist for months due to nerve disruption""",

        "diet_preop": """PRE-OPERATIVE DIET FOR CAESAREAN SECTION

If your C-section is PLANNED (elective):

NIGHT BEFORE SURGERY:
- Eat a normal dinner before midnight
- 100g carbohydrate drink (e.g. 500ml apple juice) the night before — reduces post-surgery hunger and nausea
- Immunonutrition (arginine, omega-3, antioxidants) 5 days pre-op if you are nutritionally at risk
- High-protein meals in the 2 weeks before surgery: target 1.5g protein per kg of body weight per day
- Good protein sources in Kenya: eggs (mayai), fish (samaki), chicken (kuku), lentils (dengu), beans (maharagwe), omena
- Iron-rich foods if you are anaemic: red meat, lentils, dark green vegetables, liver (ini). Take with Vitamin C foods to improve absorption.
- Avoid: alcohol, tobacco, unnecessary medications without doctor approval

2 HOURS BEFORE ARRIVAL AT HOSPITAL:
- 50g carbohydrate drink (e.g. 250ml apple juice) — reduces metabolic stress of surgery
- No solid food after this point

If your C-section is EMERGENCY:
- Nothing by mouth (NBM) — do not eat or drink anything
- Your stomach must be empty for safe anaesthesia""",

        "diet_postop": """POST-OPERATIVE DIET AFTER CAESAREAN SECTION — DAY BY DAY

HOURS 0-4 AFTER SURGERY:
Nil by mouth. Your body is clearing the anaesthetic. No food or drinks.

HOURS 4-8 AFTER SURGERY:
Clear liquids only. Sip slowly to avoid nausea.
✓ Water (maji) — start with small sips
✓ Clear broth (mchuzi wa kuku bila mafuta)
✓ Oral rehydration salts (ORS / maji ya chumvi na sukari)
✓ Weak tea without milk
✗ NO milk, juice with pulp, solid food

DAY 1 (First full day after surgery):
Soft bland diet. Your bowel is just waking up.
✓ Uji wa unga (thin porridge) — excellent first food
✓ Ugali laini (soft ugali) with small amount of soup
✓ Soft white bread with tea
✓ Boiled potatoes (viazi vya kuchemshwa)
✓ Clear fruit juice (maji ya matunda bila pulp)
✗ NO carbonated drinks (soda/fizzy drinks cause gas pain)
✗ NO fried or fatty foods

DAYS 2-3:
Semi-solid foods. Begin building protein for wound healing.
✓ Eggs (mayai ya kuchemshwa au kukaanga kidogo) — excellent protein
✓ Soft fish (samaki laini) — especially omena or tilapia without hard bones
✓ Soft chicken (kuku laini ya kuchemshwa)
✓ Mashed potatoes (viazi iliyosagwa)
✓ Ripe bananas (ndizi mbivu)
✓ Soft cooked vegetables
Continue drinking plenty of water — at least 2 litres per day

DAYS 4-7:
Full diet with focus on iron and Vitamin C for blood rebuilding.
Blood loss during C-section is 500-1000ml — your body needs to rebuild it.
✓ Iron-rich foods: liver (ini), red meat (nyama nyekundu), lentils (dengu), spinach (mchicha)
✓ Vitamin C with every iron-rich meal: orange juice, tomatoes — helps iron absorption
✓ Continue high protein: chicken, fish, eggs, beans
✗ AVOID constipation triggers: eat enough fibre and drink water
✗ AVOID straining — it stresses your incision

WEEKS 2-6 (Recovery period):
High-fibre diet to prevent straining on wound during bowel movements.
✓ Sukuma wiki (kale) — fibre, iron, folate
✓ Spinach (mchicha)
✓ Whole grain foods: brown ugali, whole wheat bread
✓ Fresh fruits: papaya (pawpaw/papai), mango, pineapple
✓ 1.5-2 litres of water every day
✓ Beans, lentils, chickpeas — fibre and protein

FOR BREASTFEEDING MOTHERS:
Your body needs extra calories and nutrients to make breast milk.
✓ +500 extra calories per day above your normal intake
✓ Calcium-rich foods EVERY DAY: milk (maziwa), yoghurt (mtindi), omena (dried small fish — very high calcium), dark greens
✓ Omega-3 for baby's brain development: fish 3x per week (samaki, sardines, mackerel)
✗ AVOID: alcohol, raw fish, large fish (high mercury risk), excessive tea or coffee
✗ AVOID: foods that cause colic in baby (some mothers find cabbage, onions cause issues)

FOODS TO AVOID AFTER C-SECTION:
✗ Alcohol (slows wound healing, passes to breast milk)
✗ Carbonated drinks / soda (causes painful gas)
✗ Spicy foods for the first week (can cause discomfort)
✗ Highly processed foods, fried foods
✗ Excessive salt (increases fluid retention and wound swelling)""",

        "nutrients_research": """KEY NUTRIENTS FOR C-SECTION RECOVERY AND RESEARCH EVIDENCE

KEY NUTRIENTS:
• IRON — essential to rebuild blood lost during surgery (normal blood loss 500-1000ml)
  Sources in Kenya: omena, liver (ini), lentils (dengu), spinach (mchicha), red meat, maharagwe
  Take with Vitamin C for better absorption

• VITAMIN C — needed for collagen formation (wound healing) and iron absorption
  Sources: oranges, tomatoes, guava (mapera), capsicum/pilipili hoho

• CALCIUM — essential for breastfeeding mothers (baby takes calcium from mother's bones)
  Sources: milk (maziwa), yoghurt (mtindi), omena (highest calcium in Kenya per gram), dark greens

• PROTEIN (≥1.5g per kg body weight per day) — critical for wound repair, tissue rebuilding
  Sources: eggs, chicken, fish, beans, lentils, milk

• ZINC — wound healing enzyme, immune function
  Sources: red meat, chicken, pumpkin seeds, legumes

• OMEGA-3 FATTY ACIDS — reduces inflammation, supports baby's brain development
  Sources: sardines, mackerel, omena, salmon (expensive but available)

• FOLATE — especially important if breastfeeding
  Sources: dark green vegetables, lentils, beans

RESEARCH EVIDENCE (2021-2025):
- The ERAS (Enhanced Recovery After Surgery) Society 2025 guidelines for C-sections recommend early oral feeding within 4-8 hours post-op, carbohydrate loading pre-op, and high-protein nutrition to reduce hospital stay.
- A population-based cohort study of 79,052 women (PLOS ONE, 2021) found C-section is associated with 2.92x higher risk of bowel obstruction and 2.71x higher risk of incisional hernia compared to vaginal birth — emphasising the need for fibre to prevent straining.
- ERAS adherence in sub-Saharan African hospitals was only ~40% (PMC, Ethiopia, 2024) — early oral feeding was the key gap. SalamaRecover addresses this directly.""",
    },

    # ─── HERNIA REPAIR ──────────────────────────────────────────────────────
    {
        "name": "Inguinal Hernia Repair",
        "code": "HERNIA",
        "specialty": "General Surgery",

        "overview": """INGUINAL HERNIA REPAIR — OVERVIEW

An inguinal hernia occurs when abdominal contents (usually a portion of intestine or fatty tissue) protrude through a weak spot in the inguinal canal in the groin area. It is one of the most common operations worldwide — approximately 800,000 hernia repairs are performed each year in the USA alone.

In Kenya, hernia repair is common at county hospitals and national referral hospitals. It is more common in males (lifetime risk ~27%) than females (lifetime risk ~3%).

TYPES OF APPROACH:
- Open (Lichtenstein mesh repair) — most common in Kenya's public hospitals. A groin incision is made, the hernia is repaired, and a mesh is placed to reinforce the area.
- Laparoscopic (TEP/TAPP) — minimally invasive, 3 small incisions. Faster recovery, less chronic pain, but requires specialised equipment.
- Robotic — available at Aga Khan University Hospital Nairobi. Fewest complications, fastest recovery.

RECOVERY TIMELINE:
- Hospital stay: 1-2 days (open), day surgery (laparoscopic)
- Return to light activity: Day 3-5
- No heavy lifting: 6 weeks
- Full recovery: 4-6 weeks
- Return to strenuous work: 6-8 weeks""",

        "procedure": """INGUINAL HERNIA REPAIR — SURGICAL PROCEDURE

OPEN LICHTENSTEIN REPAIR (most common in Kenya):
1. Groin incision (~5-7cm) over the inguinal canal
2. Hernia sac identified and dissected free
3. If incarcerated (trapped): sac contents carefully returned to abdomen
4. Mesh placed flat over the defect to reinforce the abdominal wall
5. Mesh fixed with sutures to surrounding tissue
6. Wound closed in layers — fascia, subcutaneous tissue, skin

LAPAROSCOPIC REPAIR (TEP — Totally Extraperitoneal):
1. Three small ports (5-12mm) in the lower abdomen
2. The space behind the abdominal muscles is developed with gas
3. A large mesh (~15x10cm) placed to cover the entire myopectineal orifice
4. No suture fixation needed (mesh held by abdominal pressure)
5. Ports closed — no external mesh, no inguinal incision

Duration: Open ~60-90 minutes, Laparoscopic ~45-60 minutes

WHAT TO EXPECT AFTER SURGERY:
- Groin pain and scrotal bruising/swelling are normal and expected
- Pain peak Day 1-3, significantly better by Day 7
- Mild scrotal swelling can persist for 2-4 weeks
- Wound numbness around the incision — nerves take months to recover
- Wearing supportive underwear reduces discomfort""",

        "complications": """INGUINAL HERNIA REPAIR — COMPLICATIONS AND WARNING SIGNS

SERIOUS COMPLICATIONS (SEE A DOCTOR):
- Hernia recurrence: 1-5% with mesh repair. Signs: new bulge in the groin, pain with straining. Usually appears 1-5 years post-surgery.
- Mesh infection: Rare but serious. Fever, persistent wound pain, redness, discharge at incision. Requires antibiotics; occasionally mesh removal.
- Injury to vas deferens (tube carrying sperm): Rare. Can affect fertility.
- Testicular atrophy: Very rare. If blood supply to testicle is disrupted. Signs: testicle becoming smaller, painful.
- Haematoma: Large blood collection in scrotum. Very swollen, tense, painful. Needs surgical drainage if large.
- Intestinal injury: Rare but serious. Severe abdominal pain, fever, vomiting. EMERGENCY.

COMMON BUT NOT DANGEROUS:
- Chronic inguinodynia (long-term groin pain): Most common long-term issue. Present in 10-15% of patients. Usually improves over 12 months.
- Scrotal bruising (purple/black): Normal, resolves in 2-3 weeks
- Seroma: Fluid collection under wound — feels like a soft lump. Usually resolves without treatment.
- Numbness of inner thigh or scrotum: Nerve disruption, usually temporary.
- Difficulty urinating first 24 hours: Common after spinal anaesthesia — usually resolves.

EMERGENCY SIGNS — GO TO HOSPITAL IMMEDIATELY:
- Fever above 38°C
- Wound discharge or opening
- Inability to pass stool or gas after Day 3 (possible bowel complication)
- Severe increasing pain at Day 3+ (should be improving, not worsening)""",

        "diet_preop": """PRE-OPERATIVE DIET FOR HERNIA REPAIR

1-2 WEEKS BEFORE SURGERY:
The most important dietary goal before hernia repair is establishing a regular bowel habit to prevent straining post-surgery. Straining is the biggest threat to the hernia repair — it can displace the mesh before it heals.

✓ HIGH-FIBRE DIET: Start 1-2 weeks pre-op
  - Fruits: banana, papaya, mango, oranges
  - Vegetables: sukuma wiki, spinach, carrots
  - Whole grains: brown rice, whole wheat ugali, oats
  - Legumes: maharagwe (beans), lentils, dengu
  - 2 litres of water per day

✓ FOODS CAUSING GAS — LIMIT:
  Reduce beans, cabbage, carbonated drinks in the week before surgery to reduce post-op gas pain.

NIGHT BEFORE AND DAY OF SURGERY:
- Normal dinner the night before (unless instructed otherwise)
- 100g carbohydrate drink (500ml apple juice) the evening before surgery
- 2 hours before arrival: 50g carbohydrate drink (250ml apple juice) — reduces surgical stress
- Nothing to eat or drink after that (nil by mouth for safe anaesthesia)""",

        "diet_postop": """POST-OPERATIVE DIET AFTER HERNIA REPAIR — DAY BY DAY

The single most important dietary goal after hernia repair is PREVENTING CONSTIPATION. Straining to pass stool puts pressure on the mesh before it has integrated into the tissue (takes 4-6 weeks).

DAY 0-1 (Surgery day and first day):
✓ Clear liquids — water, broth, weak tea
✓ Sip slowly to avoid gas pain
✓ AVOID straining at all costs — call for help if you need to pass stool
✓ Walk a little if you can — movement helps gas pass

DAYS 2-3:
Soft, LOW-FIBRE foods initially (to reduce gas while wound is fresh):
✓ White rice (wali mweupe)
✓ Boiled eggs (mayai ya kuchemsha)
✓ Ripe banana (ndizi mbivu) — easy to digest
✓ Boiled fish (samaki ya kuchemsha) — white fish, omena
✓ Boiled potato (kiazi)
✓ Toast with tea
✗ AVOID: beans, cabbage, carbonated drinks, fried foods, spicy foods

DAYS 4-7:
Begin gradually reintroducing fibre:
✓ Soft-cooked vegetables: carrots, peas
✓ Cooked fruits: stewed papaya
✓ Soft ugali with vegetable stew
✓ Continue lean protein: eggs, fish, chicken
✓ 2+ litres of water daily
✗ AVOID heavy lifting while eating (increases intra-abdominal pressure)

WEEKS 2-6 (Critical period — mesh integration):
HIGH-FIBRE diet is now CRITICAL:
✓ Fruits: papaya (pawpaw), mango, oranges
✓ Vegetables: sukuma wiki, spinach, pumpkin (malenge)
✓ Whole grains: brown rice, whole wheat bread
✓ Legumes: well-cooked beans and lentils
✓ 2+ litres of water per day
✓ Stool softeners if needed (lactulose available at chemists)
✓ PROTEIN: 1.2-1.5g per kg body weight per day for mesh integration
  Sources: chicken, fish, eggs, milk, legumes
✗ AVOID: spicy foods, carbonated drinks, alcohol
✗ AVOID: anything causing you to strain or cough hard (protects mesh)""",

        "nutrients_research": """KEY NUTRIENTS FOR HERNIA REPAIR RECOVERY

• DIETARY FIBRE (25-35g per day) — THE MOST IMPORTANT nutrient after hernia repair
  Prevents constipation and straining, which is the biggest risk to mesh integrity
  Sources: sukuma wiki, spinach, beans, whole grain ugali, fruits, oats

• PROTEIN (1.2-1.5g/kg/day) — supports mesh integration and wound healing
  Sources: eggs, chicken, fish, omena, milk, beans, lentils

• WATER (minimum 2 litres/day) — essential for bowel function and wound healing
  Dehydration causes constipation, which causes straining

• ZINC — wound healing enzyme, collagen synthesis
  Sources: red meat, chicken, pumpkin seeds, legumes

• VITAMIN C — collagen synthesis for wound and mesh integration
  Sources: oranges, tomatoes, guava

RESEARCH EVIDENCE:
- Systematic review of open vs laparoscopic vs robotic hernia repair (PMC/MDPI 2025): All three techniques are safe. Robotic shows the lowest conversion-to-open rate. In Kenya, open repair (Lichtenstein) remains most common due to resource availability.
- Propensity-matched outcome analysis (Surgery, Elsevier 2024): All techniques show comparable safety and effectiveness. Open repair more common in patients with comorbidities.""",
    },

    # ─── APPENDECTOMY ────────────────────────────────────────────────────────
    {
        "name": "Appendectomy",
        "code": "APPY",
        "specialty": "General Surgery",

        "overview": """APPENDECTOMY — OVERVIEW AND KENYA CONTEXT

An appendectomy is the surgical removal of the vermiform appendix, a small finger-like pouch attached to the large intestine. It is most commonly performed for acute appendicitis (inflammation of the appendix). If not treated, appendicitis can lead to perforation (rupture), which is a life-threatening emergency.

Appendectomy has the shortest mean operating time of all common surgical procedures (~51 minutes). Lifetime risk of appendicitis is 7-8%.

IN KENYA:
Appendectomy is performed at all levels of the health system. Open appendectomy (McBurney incision in right lower abdomen) remains common at district hospitals due to limited laparoscopic equipment. Laparoscopic appendectomy is available at KNH, Nairobi Hospital, Aga Khan, and major private hospitals.

RECOVERY TIMELINE:
- Hospital stay: 1-2 days (uncomplicated laparoscopic), 2-4 days (open or perforated)
- Return to light activity: Day 3-5 (laparoscopic), Day 7 (open)
- Return to work/school: Day 7-14
- Full recovery: 2-4 weeks
- Heavy exercise: after 4-6 weeks

PERFORATED APPENDICITIS (ruptured):
Recovery is longer — 5-7 days hospital stay, antibiotics for 5-7 days, drain may be placed.
Diet progression is slower. Watch carefully for fever, which may indicate abscess.""",

        "procedure": """APPENDECTOMY — SURGICAL PROCEDURE

LAPAROSCOPIC APPENDECTOMY (minimally invasive — preferred when available):
1. Three small ports (5-12mm) in the abdomen
2. Carbon dioxide gas inflated to create working space
3. Camera inserted — full view of the abdomen
4. Appendix identified and its blood supply (mesoappendix) divided
5. Appendix base secured with stapler or endoloops
6. Appendix divided and extracted through a port
7. Abdomen irrigated if perforated
8. Ports closed — 3 tiny incisions, less pain, faster recovery

OPEN APPENDECTOMY (McBurney — most common in Kenya public hospitals):
1. Right lower abdominal incision (~5-7cm) at McBurney's point
2. Appendix identified through incision
3. Mesoappendix ligated
4. Appendix base tied with suture and appendix removed
5. Wound closed in layers
6. If perforated: thorough irrigation + drain placed

PERFORATED APPENDICITIS:
Requires urgent surgery. Additional steps include thorough washout with saline of the entire abdomen, drain placement, and IV antibiotics for 5-7 days.

WHAT TO EXPECT:
- Laparoscopic: 3 small adhesive dressings, minimal pain, eating same day
- Open: larger dressing, more wound pain Day 1-3
- Gas shoulder pain after laparoscopy (trapped CO₂ irritates diaphragm) — normal, resolves in 24-48 hours""",

        "complications": """APPENDECTOMY — COMPLICATIONS AND WARNING SIGNS

SERIOUS COMPLICATIONS:
- Wound infection: Fever above 38°C + wound redness/swelling/discharge at incision. Risk is higher with open surgery and perforated appendicitis. Seen Day 3-7.
- Intra-abdominal abscess: Fever persisting after Day 3, abdominal pain, not eating well. Most common after perforated appendicitis. Diagnosed by ultrasound. Treated with antibiotics or drainage.
- Stump leak / appendiceal stump blowout: Very rare but serious. Severe abdominal pain, fever, vomiting 3-7 days post-op. Requires emergency surgery.
- Ileus (bowel not waking up): No bowel sounds, distended abdomen, nausea, not passing gas. Usually resolves with walking and IV fluids. Common after perforated appendix.
- Port-site hernia (laparoscopic): Bulge at one of the small incisions (usually develops weeks later).

WHEN TO GO TO HOSPITAL IMMEDIATELY:
- Fever above 38°C after Day 2
- Worsening abdominal pain (should be improving each day)
- Vomiting that won't stop
- Abdominal distension (swelling)
- No bowel movement or gas after Day 3
- Wound opening, discharge, or increasing redness
- Severe pain in right shoulder lasting more than 48 hours (could indicate subphrenic abscess)

NORMAL SYMPTOMS:
- Mild wound pain, improving each day
- Slight bloating for 1-2 days (trapped gas from surgery)
- Fatigue for the first week
- Loose stools initially — normal after bowel manipulation""",

        "diet_preop": """PRE-OPERATIVE DIET FOR APPENDECTOMY

EMERGENCY APPENDECTOMY (most common):
If appendicitis is diagnosed, surgery happens urgently.
- NOTHING BY MOUTH IMMEDIATELY (nil by mouth / NPO)
- Do not eat or drink anything — tell staff if you ate recently
- Your anaesthetic team needs to know when you last ate

ELECTIVE / INTERVAL APPENDECTOMY (planned surgery):
- Full meal allowed up to 6 hours before surgery
- Clear liquids (water, juice) allowed up to 2 hours before
- No specific pre-operative dietary restriction beyond standard surgical fasting
- Stay well hydrated the day before — drink 2 litres of water""",

        "diet_postop": """POST-OPERATIVE DIET AFTER APPENDECTOMY — DAY BY DAY

KEY PRINCIPLE: Start simple and build up gradually. The bowel needs time to wake up after surgery.

DAY 0 (Surgery day — when you wake up):
✓ Clear liquids when you are alert and not vomiting
✓ Water (maji) — start with small sips
✓ Clear broth (mchuzi wa kuku bila mafuta)
✓ Oral rehydration salts
✓ Weak tea without milk
✗ NO solid food yet
✗ NO milk or fruit juice yet

DAY 1 (First day after surgery):
Soft, low-fibre diet:
✓ White rice (wali mweupe laini)
✓ Toast (mkate wa kukaanga kidogo) with tea
✓ Boiled potato (kiazi cha kuchemsha)
✓ Ripe banana (ndizi mbivu)
✓ Boiled white fish or omena
✗ AVOID: raw vegetables, legumes, beans, carbonated drinks

DAYS 2-3:
Building up gradually:
✓ Add soft-cooked vegetables: peas, carrots, pumpkin (malenge)
✓ Eggs (mayai ya kuchemsha au omelette)
✓ Soft chicken or fish
✓ Mashed potato with chicken stock
✓ Begin soft fruit: stewed papaya, ripe mango
✗ AVOID raw foods and hard legumes

DAYS 4-7:
Gradually increase fibre:
✓ Soft ugali with vegetable stew
✓ Lentil soup (mchuzi wa dengu laini)
✓ Cooked fruits and vegetables
✓ Protein continues to be important: 1.2g/kg/day
✓ 2 litres of water per day

WEEK 2 AND BEYOND:
High-fibre full diet to prevent constipation:
✓ Sukuma wiki, spinach, pumpkin
✓ Whole grain ugali, brown rice
✓ All fruits
✓ Beans and lentils (well cooked)
✓ 2 litres of water daily

FOR PERFORATED APPENDICITIS:
Progression is SLOWER — your bowel was more severely disturbed.
May need IV nutrition for the first 1-2 days.
Start clear liquids only when bowel sounds return and you pass gas.
Progress through each stage slowly — do not rush.

IMPORTANT FOODS FOR RECOVERY:
✓ Probiotics (natural yoghurt/mtindi) — helps restore gut bacteria after antibiotics
✓ Zinc-rich foods for wound healing: red meat, chicken, pumpkin seeds
✓ Vitamin C: oranges, tomatoes, guava — collagen synthesis""",

        "nutrients_research": """KEY NUTRIENTS FOR APPENDECTOMY RECOVERY

• PROTEIN (1.2g/kg/day) — wound healing, tissue repair
  Sources: eggs (mayai), fish (samaki), chicken (kuku), lentils (dengu), milk (maziwa)

• ZINC — essential for wound healing enzyme function
  Sources: red meat, chicken, pumpkin seeds (mbegu za malenge), legumes

• VITAMIN C — collagen synthesis for wound closure
  Sources: oranges (machungwa), tomatoes (nyanya), guava (mapera)

• PROBIOTICS — restore healthy gut bacteria after antibiotics (commonly given after appendectomy)
  Sources: natural yoghurt (mtindi), fermented milk, fermented uji

• WATER — at least 2 litres daily for bowel recovery and wound healing

• FIBRE (after Day 3) — prevents constipation and post-surgical ileus
  Sources: sukuma wiki, fruits, whole grain ugali, well-cooked beans

RESEARCH EVIDENCE:
- Multiple meta-analyses (PMC, 2023): Laparoscopic appendectomy shows fewer wound infections than open surgery; open remains more accessible in Kenya and sub-Saharan Africa.
- Appendectomy safely combined with umbilical hernia repair with comparable 90-day outcomes (Hernia, Springer 2024).""",
    },

    # ─── CHOLECYSTECTOMY ─────────────────────────────────────────────────────
    {
        "name": "Cholecystectomy",
        "code": "CHOLE",
        "specialty": "General Surgery",

        "overview": """CHOLECYSTECTOMY — OVERVIEW AND KENYA CONTEXT

Cholecystectomy is the surgical removal of the gallbladder. It is most commonly performed for symptomatic gallstones (cholelithiasis) or cholecystitis (gallbladder inflammation). Approximately 1 million cholecystectomies are performed annually in the USA. In Kenya and East Africa, the procedure is increasing as dietary patterns shift toward higher fat intake (urbanisation).

Laparoscopic cholecystectomy (LC) is the gold standard worldwide. Available at Kenyatta National Hospital, Nairobi Hospital, Aga Khan University Hospital. Open cholecystectomy (right subcostal/Kocher incision) is performed when laparoscopic is not possible or conversion is needed.

WHY IS THE GALLBLADDER REMOVED?
The gallbladder stores bile (a digestive fluid made by the liver). When bile contains too much cholesterol or bilirubin, gallstones form. These can cause:
- Biliary colic: severe right upper abdomen pain after fatty meals (pain can radiate to right shoulder)
- Acute cholecystitis: gallbladder infection (fever + right upper pain + nausea)
- Jaundice: if a stone blocks the bile duct
- Pancreatitis: if a stone blocks the pancreatic duct (emergency)

LIFE WITHOUT A GALLBLADDER:
The liver continues to make bile, but it drips continuously into the intestine instead of being stored. Most people live completely normally without a gallbladder. A minority (~10-15%) develop post-cholecystectomy syndrome (loose stools after fatty meals) — managed with a low-fat diet.

RECOVERY TIMELINE:
- Laparoscopic: 1 day hospital stay, return to light activities Day 3-5, full recovery 2 weeks
- Open: 3-5 day hospital stay, full recovery 4-6 weeks""",

        "procedure": """CHOLECYSTECTOMY — SURGICAL PROCEDURE

LAPAROSCOPIC CHOLECYSTECTOMY (4-port technique):
1. 4 small ports (5-12mm) — one at umbilicus (navel), three in right upper abdomen
2. Carbon dioxide inflated to create working space
3. Calot's triangle dissected — the critical anatomy where cystic duct and cystic artery are identified
4. Critical view of safety (CVS) confirmed — mandatory step to prevent bile duct injury
5. Cystic duct and cystic artery clipped (two clips each) and divided
6. Gallbladder dissected off liver bed with electrocautery
7. Gallbladder extracted through the umbilical port (in a bag to prevent spillage)
8. Ports removed, CO₂ released, wounds closed

OPEN CHOLECYSTECTOMY (Kocher incision):
1. Right subcostal incision (under right rib cage, ~15cm)
2. Same steps as above but performed under direct vision
3. Drain may be placed near the gallbladder bed
4. Wound closed in layers

Duration: Laparoscopic 45-90 minutes, Open 60-120 minutes

WHAT TO EXPECT:
- Right shoulder tip pain for 24-48 hours (trapped CO₂ irritates diaphragm — completely normal)
- Right upper abdominal tenderness for 5-7 days
- Mild nausea Day 1-2
- Loose or fatty stools for the first 2-4 weeks (while bowel adjusts to continuous bile flow)""",

        "complications": """CHOLECYSTECTOMY — COMPLICATIONS AND WARNING SIGNS

SERIOUS COMPLICATIONS:
- Bile duct injury: The most feared complication (0.3-0.5%). Injury to the common bile duct causes bile leakage. Signs: worsening abdominal pain, jaundice (yellow skin/eyes), fever after Day 2. Requires urgent specialist assessment.
- Bile leak: Bile oozes from the cut surface or a clip comes loose. Signs: abdominal pain, distension, fever 2-5 days post-op. Managed with ERCP (endoscopic procedure) or surgery.
- Haemorrhage: Bleeding from cystic artery or liver bed. Severe abdominal pain, dropping blood pressure. Rare but requires urgent intervention.
- Retained common bile duct stone: If a stone was present in the bile duct. Signs: jaundice, fever, right upper pain 1-2 weeks post-op. Managed with ERCP.
- Port-site hernia: Bulge at one of the incision sites. Usually appears weeks to months later.

COMMON SYMPTOMS (normal, not dangerous):
- Right shoulder tip pain 24-48 hours: trapped CO₂, resolves spontaneously
- Loose, oily, or pale stools for 2-4 weeks: bowel adjusting to no gallbladder
- Mild nausea first 48 hours: anaesthetic effect
- Fatigue for 1-2 weeks: normal healing response
- Bloating after meals for 2-4 weeks: normal adjustment

WHEN TO SEEK IMMEDIATE HELP:
- Fever above 38°C after Day 2
- Yellow eyes or skin (jaundice)
- Worsening right upper abdominal pain
- Dark urine + pale stools (suggests bile duct problem)
- Vomiting that won't stop
- Wound infection signs: redness, swelling, discharge""",

        "diet_preop": """PRE-OPERATIVE DIET FOR CHOLECYSTECTOMY

2-4 WEEKS BEFORE SURGERY (if planned/elective):
LOW-FAT DIET is essential to reduce gallbladder contraction (reduces pain and inflammation).

✓ Allowed:
  - Lean fish (samaki ya nyama nyeupe): tilapia, omena, whitebait
  - Chicken without skin (kuku bila ngozi)
  - Boiled eggs (kuchemsha, not frying) — limit to 1 per day
  - Fruits and vegetables — all types
  - Boiled or steamed grains: rice, ugali, bread
  - Low-fat milk, yoghurt (mtindi bila mafuta)
  - 2+ litres of water per day

✗ Avoid strictly:
  - Fried foods: mandazi ya kukaanga, chips, kuku wa kukaanga
  - Fatty meats: goat ribs, fatty beef, pork
  - Full-fat dairy: whole milk, cream, butter (siagi), ghee (samli)
  - Coconut milk (maziwa ya nazi) — very high fat, triggers gallbladder attack
  - Avocado (high fat — avoid until after surgery)
  - Oil-heavy cooking (cook with minimal oil or steam)
  - Large meals — eat small frequent meals instead (prevents large gallbladder contractions)

NIGHT BEFORE AND DAY OF SURGERY:
- 100g carbohydrate drink (500ml apple juice) the evening before
- 50g carbohydrate drink (250ml apple juice) 2 hours before
- Nothing after that (nil by mouth)""",

        "diet_postop": """POST-OPERATIVE DIET AFTER CHOLECYSTECTOMY — DAY BY DAY

KEY PRINCIPLE: The gallbladder is gone — your body can no longer concentrate or store bile. Bile now drips continuously into your intestine. Until your body adjusts, fatty meals will cause diarrhoea and discomfort.

DAY 0-1:
✓ Clear liquids only: water, broth, ORS, weak tea
✓ NO fat whatsoever

DAYS 2-3:
Very-low-fat soft diet:
✓ Boiled white rice (wali mweupe)
✓ Boiled vegetables: carrots, spinach, peas
✓ Lean fish: tilapia, omena (minimal oil)
✓ Ripe banana (ndizi)
✓ Plain uji wa unga (no fat added)
✗ NO eggs (contain fat — reintroduce slowly in Week 2)
✗ NO avocado, coconut milk, butter, ghee, whole milk

WEEK 1:
Less than 10g fat per day. Introduce small amounts of healthy fat very gradually.
✓ Boiled or steamed foods preferred
✓ A small drizzle of sunflower oil (1 teaspoon) in cooking is acceptable
✓ Continue lean proteins: fish, chicken without skin, lentils
✓ HIGH-FIBRE: sukuma wiki, fruits, beans (helps bile acid absorption)
✓ 2+ litres water daily

WEEKS 2-4:
Low-fat diet (<30g fat per day):
✓ Gradually reintroduce eggs (1 per day, boiled)
✓ Continue avoiding fried foods entirely
✓ Small portions of avocado (quarter portion) can be tried — if no diarrhoea, gradually increase
✓ Regular ugali, rice, chapati (minimal ghee)
✓ Yoghurt (mtindi) — low fat version is fine
✓ Most Kenyan stews and soups are acceptable if cooked with minimal oil

MONTH 2 AND BEYOND:
Most people can return to a normal diet by 4-8 weeks.
✓ Gradually reintroduce normal fats — test small amounts first
✓ If diarrhoea occurs after fatty meal: reduce that food for another 2-4 weeks
✓ SOME PATIENTS develop post-cholecystectomy syndrome — loose stools after fatty meals — permanently. These patients should maintain a low-fat diet indefinitely.

FOODS THAT TEND TO CAUSE PROBLEMS:
✗ Fried foods (chips/crisps, fried chicken, mandazi)
✗ Fatty meats (goat ribs, pork, fatty beef)
✗ Coconut milk-based dishes (heavily used in coastal Kenyan cooking)
✗ Creamy sauces, full-fat milk, butter
✗ Alcohol""",

        "nutrients_research": """KEY NUTRIENTS FOR CHOLECYSTECTOMY RECOVERY

• LOW FAT — most critical dietary modification
  Without a gallbladder, the body cannot efficiently digest large fat loads
  Target: <10g fat/day in Week 1, <30g fat/day in Weeks 2-4

• FAT-SOLUBLE VITAMINS (A, D, E, K) — monitor if fat malabsorption persists
  If you have ongoing loose stools with fat in them (steatorrhoea), these vitamins may be poorly absorbed
  Sources: Vitamin A (liver, eggs, dark green vegetables), Vitamin D (sunlight, fish)

• FIBRE — high fibre helps manage bile acid diarrhoea (binds excess bile acids)
  Sources: sukuma wiki, spinach, beans, whole grain ugali, fruits

• PROTEIN — for wound healing
  Sources: lean fish, chicken, eggs (from Week 2), lentils, low-fat milk

• WATER — 2+ litres daily; prevents bile sludge formation in bile ducts

RESEARCH EVIDENCE:
- Systematic review (NCBI Bookshelf, 2020): Robotic cholecystectomy shows lower conversion to open than laparoscopic. Cost-effectiveness debated for low-resource settings like Kenya.
- Combined cholecystectomy and hernia repair meta-analysis (ScienceDirect, Heliyon 2024): Safe when gallbladder is intact. Combining procedures reduces total anaesthetic exposure.""",
    },

    # ─── HYSTERECTOMY ────────────────────────────────────────────────────────
    {
        "name": "Hysterectomy",
        "code": "HYST",
        "specialty": "Gynaecology",

        "overview": """HYSTERECTOMY — OVERVIEW AND KENYA CONTEXT

Hysterectomy is the surgical removal of the uterus. It is the most common non-obstetric major surgery in women worldwide. In Kenya and sub-Saharan Africa, uterine fibroids (myomas) are the most common indication — affecting up to 70-80% of Black women by age 50.

TYPES OF HYSTERECTOMY:
- Total abdominal hysterectomy (TAH): uterus + cervix removed, Pfannenstiel or midline incision. Most common in Kenya's public hospitals.
- Laparoscopic: 3-4 small ports. Faster recovery. Available at Nairobi Hospital, Aga Khan, KNH.
- Vaginal (VH): uterus removed through vagina, no abdominal incision. Uncommon in Kenya.
- Robotic: highest precision, fastest recovery. Available at Aga Khan University Hospital.

DOES REMOVING THE UTERUS CAUSE MENOPAUSE?
No — menopause only occurs if the ovaries are also removed (bilateral oophorectomy).
- Uterus only removed → menstrual periods stop, but no menopause symptoms
- Uterus + ovaries removed → surgical menopause begins (hot flushes, bone loss, etc.)

RECOVERY TIMELINE:
- TAH: 4-7 day hospital stay, full recovery 6-8 weeks
- Laparoscopic: 1-2 day hospital stay, full recovery 2-4 weeks
- Return to light activities: 2 weeks (laparoscopic), 4 weeks (open)
- Driving: after 4-6 weeks (check with doctor)
- No sexual intercourse: 6-8 weeks (vaginal vault must heal)""",

        "procedure": """HYSTERECTOMY — SURGICAL PROCEDURE

TOTAL ABDOMINAL HYSTERECTOMY (TAH):
1. Pfannenstiel (bikini line) or midline incision under spinal/general anaesthesia
2. Uterine ligaments and vessels identified and secured (clamped, cut, sutured)
3. Ligation of the uterine arteries — major step to control bleeding
4. Division of the cardinal ligaments and uterosacral ligaments
5. Cervix transected from the vaginal vault
6. Vault closure with absorbable sutures
7. Haemostasis confirmed
8. Abdominal closure in layers

LAPAROSCOPIC HYSTERECTOMY (TLH — Total Laparoscopic):
Same steps as above but performed with robotic/laparoscopic instruments through 3-4 small ports. The vaginal vault is closed laparoscopically or vaginally.

Duration: 1.5-3 hours

WHAT TO EXPECT:
- Urinary catheter placed before surgery (removed Day 1-2)
- IV drip for fluids and antibiotics
- Drain may be placed (removed Day 2-3)
- Moderate to significant pain Day 1-3 — well managed with IV analgesia
- Vaginal discharge (pinkish-red) for 2-4 weeks — normal
- Bloating and gas for 1-2 weeks""",

        "complications": """HYSTERECTOMY — COMPLICATIONS AND WARNING SIGNS

SERIOUS COMPLICATIONS:
- Haemorrhage: Significant bleeding during or after surgery. Signs: rapid heart rate, dizziness, pallor. Usually detected in hospital.
- Urinary tract or bladder injury: Bladder or ureters (tubes from kidney to bladder) can be injured. Signs: continuous urine leakage from vagina, inability to urinate, pain.
- DVT/Pulmonary Embolism: Risk is elevated after pelvic surgery. Calf pain, leg swelling → immediate concern. Chest pain, breathlessness → EMERGENCY.
- Vaginal vault dehiscence: The vault closure opens. Signs: vaginal bleeding, something "coming out". Requires urgent surgical repair.
- Pelvic floor dysfunction: Bladder or bowel problems (urinary incontinence, prolapse) can develop months to years later.
- Premature menopause (if ovaries removed): Hot flushes, mood swings, bone loss, dry vagina — requires hormone therapy discussion with doctor.
- Lymphocele: Fluid collection in pelvis (if lymph nodes removed for cancer). Usually resolves without treatment.

WOUND SIGNS TO WATCH:
- Fever above 38°C after Day 3 — possible infection
- Increasing lower abdominal pain after initial improvement
- Foul-smelling vaginal discharge
- Redness, swelling or discharge from abdominal wound

NORMAL SYMPTOMS:
- Pinkish-red vaginal discharge for 2-4 weeks
- Fatigue for 2-6 weeks
- Mood changes, sleep disturbance (even if ovaries not removed — major surgery stress)
- Constipation for 1 week (normal after major abdominal surgery)""",

        "diet_preop": """PRE-OPERATIVE DIET FOR HYSTERECTOMY

2 WEEKS BEFORE SURGERY:
Fibroids often cause heavy menstrual bleeding, leading to iron-deficiency anaemia in most patients. Correcting this BEFORE surgery is critical to reduce the need for blood transfusion.

✓ HIGH-IRON FOODS (eat these EVERY day):
  - Liver (ini) — highest iron content of any food
  - Red meat (nyama nyekundu): beef, goat
  - Omena (small dried fish) — very iron-rich
  - Lentils (dengu) and beans (maharagwe)
  - Spinach (mchicha) and dark green vegetables
  - Iron-fortified uji/porridge

✓ VITAMIN C WITH EVERY IRON-RICH MEAL (increases iron absorption by 3-4x):
  - Squeeze orange or lemon juice on food
  - Add tomatoes (nyanya) to every meal
  - Fresh fruit juice (passion fruit, orange)

✓ HIGH-PROTEIN DIET (1.5g/kg/day):
  - Eggs, chicken, fish, milk, beans, lentils
  - Builds reserves for post-surgical healing

AVOID WITH IRON-RICH MEALS:
  - Tea and coffee (tannins block iron absorption)
  - Milk in the same meal as iron-rich food (calcium competes with iron)
  - Eat iron foods first, then wait 1 hour before tea

NIGHT BEFORE AND DAY OF SURGERY:
Standard ERAS fasting:
- 100g carbohydrate drink (apple juice) evening before
- 50g carbohydrate drink 2 hours before
- Nothing after that""",

        "diet_postop": """POST-OPERATIVE DIET AFTER HYSTERECTOMY — DAY BY DAY

DAY 0 (Surgery day):
✓ Clear liquids 4 hours after surgery (ERAS gynaecology protocol — start early!)
✓ Water, broth, ORS, weak tea
✓ Small sips only

DAY 1:
Low-fat, low-fibre, easy-to-digest foods:
✓ Soft uji (porridge) — excellent first food
✓ Boiled rice with light soup
✓ Toast with tea
✓ Ripe banana
✓ Boiled potato
✓ Manage nausea from anaesthesia — eat small amounts frequently

DAYS 2-5:
Progress to full diet while avoiding gas-causing foods:
✓ Eggs (mayai ya kuchemsha)
✓ Fish (samaki ya kuchemsha au ya mvuke)
✓ Soft chicken
✓ Cooked vegetables: carrots, spinach, peas
✓ Fruit: papaya, mango, orange
✓ Continue drinking 2 litres of water daily
✗ AVOID: beans, cabbage (cause gas and abdominal pain when bowel is inflamed)
✗ AVOID: fried and spicy foods

WEEK 2 AND BEYOND:
Full diet with anti-inflammatory and iron-rebuilding focus:
✓ HIGH-IRON diet continues (surgery causes blood loss):
  - Omena, liver (ini), lentils, spinach, red meat
  - Always with Vitamin C to maximise absorption
✓ OMEGA-3: fish 3 times per week — reduces inflammation
✓ ANTI-INFLAMMATORY FOODS: turmeric (binzari), ginger (tangawizi), berries
✓ Colourful vegetables — antioxidants speed healing
✓ Calcium-rich foods to protect bones (especially if ovaries removed)

IF OVARIES WERE REMOVED (surgical menopause):
✓ CALCIUM 1200mg/day — essential to prevent osteoporosis
  Sources: milk (maziwa), yoghurt (mtindi), omena (very high calcium), fortified uji
✓ VITAMIN D3 — helps calcium absorption. Sun exposure + fatty fish.
✓ PHYTOESTROGENS (mild benefit for hot flushes): soy products, flaxseed (ufuta), whole soy (maharagwe ya soya)
✓ PROTEIN (1.5g/kg/day) continues for 6 weeks""",

        "nutrients_research": """KEY NUTRIENTS FOR HYSTERECTOMY RECOVERY

• IRON — critical pre- and post-op (heavy bleeding from fibroids depletes iron stores)
  Target: 30-60mg elemental iron daily post-op if anaemic
  Sources in Kenya: liver (ini), omena, lentils (dengu), spinach (mchicha)

• PROTEIN (1.5g/kg/day) — pelvic surgery requires extensive tissue repair
  Sources: eggs, chicken, fish, beans, milk

• CALCIUM (1200mg/day) — essential if ovaries removed (prevents bone loss)
  Sources: milk (maziwa), yoghurt (mtindi), omena, fortified ugali

• VITAMIN D — calcium absorption, immune function, anti-inflammatory
  Sources: sunlight 30 minutes daily, fatty fish, fortified foods

• OMEGA-3 — reduces post-surgical inflammation
  Sources: sardines, mackerel, omena, salmon

• VITAMIN C — iron absorption, collagen synthesis
  Sources: oranges, tomatoes, guava

• ZINC — wound healing
  Sources: red meat, chicken, pumpkin seeds

RESEARCH EVIDENCE:
- ERAS for gynaecological surgery (ESPEN/Clinical Nutrition 2021): ERAS protocols including early feeding and immunonutrition are effective for hysterectomy. Reduces hospital stay by 1-2 days.
- ERAS GYN Nutrition Guidelines (MD Anderson 2023): Low-fat, low-fibre diet started 4 hours post-op. Immunonutrition pre-op 5-7 days reduces infectious complications.""",
    },

    # ─── KNEE REPLACEMENT ────────────────────────────────────────────────────
    {
        "name": "Knee Replacement (TKR)",
        "code": "TKR",
        "specialty": "Orthopaedics",

        "overview": """TOTAL KNEE REPLACEMENT (TKR) — OVERVIEW AND KENYA CONTEXT

Total knee replacement (TKR) is a surgical procedure that resurfaces all three compartments of the knee joint with metal and plastic implants. The primary indication is end-stage knee osteoarthritis (joint cartilage completely worn away).

IN KENYA AND EAST AFRICA:
TKR is a growing procedure at both Kenyatta National Hospital (KNH) and private hospitals (Nairobi Hospital, Aga Khan, MP Shah). A key issue in Kenya is that patients present late with advanced valgus deformity (knocked knees) because of financial constraints in seeking early care. This makes surgery technically more complex. Cemented implants are the standard in Kenya. Loss to follow-up at 6 months is 34% (Kingori & Gakuu).

RECOVERY TIMELINE — IMPORTANT: This is a LONG recovery:
- Day 1: Physiotherapist gets you standing and walking with a frame
- Week 1-2: Walking with crutches, knee bending to 90°
- Week 2-6: Increasing walking distance, stairs with support
- Month 3: Most daily activities, driving (automatic car)
- Month 6: Near-full function
- 1 Year: Full recovery and implant fully integrated

Oxford Knee Scores improve from ~15 pre-surgery to ~45 post-surgery in sub-Saharan African studies — comparable to high-income countries when surgery is done well.""",

        "procedure": """TOTAL KNEE REPLACEMENT — SURGICAL PROCEDURE

1. Spinal or general anaesthesia (spinal preferred)
2. Tourniquet applied to upper thigh to reduce bleeding
3. Medial parapatellar approach — incision over the knee, muscles retracted
4. Bone cuts made to femur (thigh bone), tibia (shin bone), and patella (kneecap) using cutting guides
5. Trial components placed to test fit and alignment
6. Surfaces cleaned and dried
7. Bone cement applied to both bone surfaces and implant
8. Metal femoral and tibial components pressed into place
9. Polyethylene (plastic) spacer inserted between metal components
10. Patella button may be resurfaced
11. Wound closed over a drain
12. Dressing applied, leg placed in straight position

Duration: 1.5-2.5 hours

WHAT TO EXPECT:
- Significant pain Day 1-5, well-controlled with IV and oral analgesia
- Drain removed Day 1-2
- Blood transfusion may be needed (major blood loss with TKR)
- Physiotherapy begins Day 1 — standing, walking with frame
- Compression stockings + anticoagulation (heparin/aspirin) to prevent DVT
- Swelling of the knee for 3-6 months is normal""",

        "complications": """TOTAL KNEE REPLACEMENT — COMPLICATIONS AND WARNING SIGNS

SERIOUS COMPLICATIONS:
- Deep infection (1.6% in sub-Saharan Africa): The most feared complication. Requires implant removal and prolonged antibiotic treatment. Signs: increasing pain after initial improvement, fever, redness, warm knee, wound discharge. Seek immediate medical care.
- DVT/PE: Very high risk after knee replacement. Calf pain, leg swelling, warmth → see doctor urgently. Chest pain, breathlessness → EMERGENCY/999.
- Aseptic loosening: Implant loosens from bone (years later). Signs: new-onset knee pain, instability. Requires revision surgery.
- Stiffness: Knee doesn't bend adequately (less than 90°). Requires intensive physiotherapy or manipulation under anaesthesia.
- Periprosthetic fracture: Bone breaks near the implant. Severe pain, instability. Emergency surgery.
- Wound dehiscence: Wound opens. Requires specialist assessment.

WATCH FOR AT HOME:
- Fever above 38°C after Day 5 — infection warning
- Increasing knee pain after Day 7 (should be improving)
- Calf pain or swelling in operated leg
- Knee much hotter than the other side after Week 2
- Wound leaking or opening after Day 5

IMPORTANT FOR KENYAN PATIENTS:
- The 34% loss to follow-up in Kenya is dangerous — implant problems found late are harder to treat
- Attend ALL physiotherapy appointments — stiffness is a major cause of poor outcomes
- Do not stop anticoagulation medications early (DVT risk is real)""",

        "diet_preop": """PRE-OPERATIVE DIET FOR KNEE REPLACEMENT

2 WEEKS BEFORE SURGERY (optimisation is CRITICAL for TKR):

HIGH-PROTEIN DIET (1.5g/kg/day) — build muscle mass before surgery
Patients lose significant muscle in the operated leg during TKR recovery. Building reserves before surgery improves outcomes.
✓ Eggs (mayai) — daily
✓ Chicken (kuku) — grilled or boiled, without skin
✓ Fish (samaki): omena, tilapia, mackerel
✓ Lentils (dengu) and beans (maharagwe)
✓ Milk (maziwa) and yoghurt (mtindi)
✓ Oral nutritional supplements if eating is poor (Ensure, Fresubin — available at major chemists)

CALCIUM AND VITAMIN D (bone strength for surgery and implant integration):
✓ Calcium 1200mg/day: milk, yoghurt, omena, dark greens
✓ Vitamin D3 800 IU/day: sunlight, fatty fish
✓ Dark leafy vegetables: sukuma wiki, spinach

WEIGHT MANAGEMENT:
Excess weight puts enormous stress on the new knee implant. Every kilogram of weight lost before surgery reduces knee load during recovery.
✓ Reduce refined carbohydrates, sugary drinks, fried foods
✓ Increase vegetables and lean protein

IRON — prevent anaemia before surgery (TKR involves significant blood loss):
✓ Liver (ini), omena, lentils, red meat + Vitamin C for absorption
✓ Iron supplements if haemoglobin is low (doctor will check)

STANDARD ERAS FASTING:
- 100g carbohydrate drink (apple juice) the evening before
- 50g carbohydrate drink 2 hours before arrival
- Nothing after that""",

        "diet_postop": """POST-OPERATIVE DIET AFTER KNEE REPLACEMENT — DAY BY DAY

KEY PRINCIPLES:
1. HIGH PROTEIN — you are rebuilding muscle in the operated leg
2. ANTI-INFLAMMATORY — reduces swelling and aids faster bend recovery
3. BONE NUTRIENTS — implant integration requires calcium and Vitamin D
4. WEIGHT MANAGEMENT — excess weight stresses the implant

DAY 0 (Surgery day):
✓ Clear liquids when awake and not vomiting
✓ Water, broth, ORS, weak tea
✓ Small sips — anaesthesia may cause nausea

DAY 1 (Physiotherapy begins today!):
Full diet is encouraged from Day 1 — you need energy for physio:
✓ Ugali with chicken or beef stew (mchuzi wa nyama)
✓ Rice with lentils or fish
✓ Eggs (mayai) — any preparation
✓ Porridge (uji) with milk
✓ Fruits and vegetables
✓ Protein supplement (Ensure/Fresubin) if eating is poor

PROTEIN (2.0g/kg/day) — ONGOING FOR 6 WEEKS:
This is the highest protein target of any surgery. You are rebuilding an entire muscle group.
✓ Lean meat: beef, goat, chicken (kuku), turkey
✓ Fish: omena, tilapia, sardines, mackerel (samaki)
✓ Eggs: 2-3 per day
✓ Beans and lentils: maharagwe, dengu, ndengu
✓ Milk (maziwa) and yoghurt (mtindi) at every meal
✓ Oral nutritional supplements (Ensure, Fresubin) — evidence shows they reduce hospitalisation cost by 12.2%

ANTI-INFLAMMATORY FOODS (reduce swelling, improve knee bend):
✓ Fatty fish: omena, sardines, mackerel (omega-3)
✓ Turmeric (binzari ya njano): add to stews and uji — powerful anti-inflammatory
✓ Ginger (tangawizi): fresh ginger in tea or cooking
✓ Berries and colourful fruits
✓ Olive oil or sunflower oil (small amounts)

CALCIUM AND VITAMIN D (implant integration — 6-12 months):
✓ Milk (maziwa) 2-3 glasses per day
✓ Yoghurt (mtindi) with every meal
✓ Omena: eat 3-4 tablespoons daily — excellent calcium
✓ Sukuma wiki (kale): good calcium and Vitamin K
✓ Vitamin D from 30 minutes of morning sunlight daily
✓ Calcium + Vitamin D supplement if eating is insufficient

HYDRATION:
✓ 2-3 litres of water per day
✓ Supports joint fluid production (synovial fluid)
✓ Prevents constipation (pain medications cause constipation)
✓ Reduces DVT risk

AVOID:
✗ Alcohol — impairs bone integration and wound healing
✗ Smoking — significantly impairs healing (discuss cessation with doctor)
✗ Junk food and excessive sugar — promotes inflammation
✗ Inactivity — you MUST do physiotherapy exercises. Movement prevents stiffness.""",

        "nutrients_research": """KEY NUTRIENTS FOR KNEE REPLACEMENT RECOVERY

• PROTEIN (2.0g/kg/day) — THE MOST CRITICAL NUTRIENT for TKR recovery
  Rebuilds quadriceps and all muscles around the knee
  Evidence: Oral nutritional supplements reduce hospitalisation cost by 12.2%
  Sources: eggs, chicken, fish, omena, milk, yoghurt, beans, lentils

• CALCIUM (1200mg/day for 6-12 months)
  Essential for implant integration (bone grows into the prosthesis)
  Sources: milk (maziwa), yoghurt (mtindi), omena (highest calcium per gram in Kenya)

• VITAMIN D3 (800-2000 IU/day)
  Required for calcium absorption and bone mineralisation
  Sources: morning sunlight, fatty fish, vitamin D supplement

• OMEGA-3 FATTY ACIDS — reduces post-surgical inflammation, improves range of motion
  Sources: sardines, omena, mackerel, flaxseed

• VITAMIN C — collagen synthesis for ligament and wound healing
  Sources: oranges, tomatoes, guava, capsicum

• COLLAGEN PRECURSORS: Vitamin C + Zinc + Copper working together
  Sources: meat, seafood, dark greens

RESEARCH EVIDENCE:
- Total joint replacement in sub-Saharan Africa: systematic review (PMC, 2019): 763 TKRs; outcomes comparable to high-income countries. Deep infection rate 1.6%. 34% loss to follow-up in Kenya is a key challenge.
- Pre- and post-surgical nutrition for muscle mass after orthopaedic surgery (PMC/Nutrients, 2021): Protein 2g/kg/day, EAA supplementation, oral nutritional supplements reduce complications and hospitalisation costs.""",
    },

    # ─── HIP REPLACEMENT ─────────────────────────────────────────────────────
    {
        "name": "Hip Replacement (THR)",
        "code": "THR",
        "specialty": "Orthopaedics",

        "overview": """HIP REPLACEMENT (TOTAL HIP REPLACEMENT/THR) — OVERVIEW AND KENYA CONTEXT

Total hip replacement (THR) resurfaces both the femoral head (ball) and acetabulum (socket) of the hip joint with metal, ceramic, and polyethylene components. In Sub-Saharan Africa and Kenya, avascular necrosis (AVN) of the femoral head is the MOST COMMON indication — unlike high-income countries where osteoarthritis dominates.

WHY AVN IS SO COMMON IN KENYA:
AVN is caused by disruption of blood supply to the femoral head, leading to bone death. In Kenya, common causes include:
- Sickle cell disease (very common in East Africa — causes blood vessel occlusion)
- Alcohol use disorder (directly toxic to bone blood vessels)
- Corticosteroid use (steroids block bone blood supply)
- HIV and antiretroviral therapy (HIV prevalence up to 33% in some SSA orthopaedic series)
- Trauma (hip fractures in elderly — femoral neck fractures)

Harris Hip Scores improve dramatically after THR: from ~28 pre-surgery to ~85 post-surgery in East African studies. Dislocation rate 1.6%, deep infection 0.5% — comparable to global standards.

RECOVERY TIMELINE:
- Hospital stay: 4-7 days
- Walking with crutches: Weeks 1-6
- Driving: 6 weeks
- Full recovery: 6-12 months
- Hip precautions (no bending >90°) for 6-12 weeks""",

        "procedure": """HIP REPLACEMENT — SURGICAL PROCEDURE

APPROACHES:
- Posterior approach: Most common in Kenya. Incision on back of hip. Higher dislocation risk.
- Anterolateral approach: Reduced dislocation risk. Growing in popularity.
- Both are safe with experienced surgeons.

SURGICAL STEPS:
1. Spinal or general anaesthesia
2. Incision over hip (10-20cm)
3. Femoral neck osteotomy — femoral head cut off and removed
4. Acetabular reaming — socket shaped to receive the cup
5. Acetabular cup placed (press-fit or cemented)
6. Liner (polyethylene or ceramic) placed inside cup
7. Femoral stem inserted into thigh bone canal (cemented)
8. New femoral head (metal or ceramic) attached to stem
9. Hip reduced (ball placed into socket)
10. Stability tested
11. Layered closure, drain placed

Duration: 1.5-3 hours

WHAT TO EXPECT:
- Pain Day 1-5, managed with IV + oral analgesia
- Physiotherapist starts mobilisation Day 1
- Strict hip precautions (no bending hip >90°, no crossing legs) for 6-12 weeks
- Anticoagulation for 4-6 weeks (DVT prevention)
- Drain removed Day 1-2""",

        "complications": """HIP REPLACEMENT — COMPLICATIONS AND WARNING SIGNS

SERIOUS COMPLICATIONS:
- Dislocation (1.6% in SSA): Hip comes out of socket. Sudden severe hip pain, leg looks shortened and rotated. EMERGENCY — go to hospital immediately.
- Deep infection (0.5% in SSA): Most serious long-term complication. Signs: fever, increasing hip pain (after initial improvement), wound discharge. Requires implant removal and IV antibiotics.
- DVT/PE: High risk after hip replacement. Calf pain + swelling (DVT) or chest pain + breathlessness (PE — EMERGENCY).
- Aseptic loosening: Implant loosens from bone (years later). Signs: pain with walking, instability. Requires revision.
- Periprosthetic fracture: Bone breaks around the implant. Severe pain, cannot walk. Emergency.
- Leg length discrepancy: One leg feels longer or shorter. Usually small (1-2cm) — manageable with shoe insert.
- Sciatic nerve injury: Weakness or numbness in foot and lower leg. Usually improves.

SICKLE CELL PATIENTS — SPECIAL RISKS:
- Sickle cell crisis after surgery (pain crisis, acute chest syndrome)
- Higher infection risk
- Higher transfusion requirement
- Ensure excellent hydration and oxygen delivery post-op

WHEN TO SEEK IMMEDIATE HELP:
- Sudden severe hip pain (dislocation)
- Fever above 38°C after Day 5
- Calf pain or swelling
- Chest pain or difficulty breathing
- Wound opening or discharge
- Leg numbness or weakness""",

        "diet_preop": """PRE-OPERATIVE DIET FOR HIP REPLACEMENT

2 WEEKS BEFORE SURGERY:
Same as knee replacement — focus on protein, calcium, and iron.

FOR SICKLE CELL PATIENTS:
✓ EXCELLENT HYDRATION: 3+ litres of water per day in the weeks before surgery
✓ Avoid dehydration triggers: excessive heat, strenuous activity, alcohol
✓ Iron-rich foods (sickle cell patients are often anaemic): liver (ini), omena, lentils
✓ Folic acid (found in dark greens) — supports red blood cell production in sickle cell
✓ Avoid cold foods/drinks that can trigger vaso-occlusive crisis

FOR ALL PATIENTS:
✓ HIGH-PROTEIN: 1.5g/kg/day — eggs, fish, chicken, beans, milk
✓ CALCIUM 1200mg/day: milk, yoghurt, omena, dark greens
✓ VITAMIN D3 800 IU/day: sunlight, fatty fish
✓ IRON if anaemic: liver, omena, lentils + Vitamin C

STANDARD ERAS FASTING:
- Apple juice 500ml evening before
- Apple juice 250ml 2 hours before
- Nothing after that""",

        "diet_postop": """POST-OPERATIVE DIET AFTER HIP REPLACEMENT — DAY BY DAY

Similar to knee replacement (TKR) protocol — the same principles apply.

KEY TARGETS:
• Protein: 2.0g/kg/day for 6 weeks
• Calcium: 1200mg/day for 6-12 months
• Vitamin D3: 800-2000 IU/day
• Hydration: 2-3 litres daily

DAILY FOOD RECOMMENDATIONS:

PROTEIN (rebuild muscle, support implant integration):
✓ Lean meat: beef, goat, chicken without skin
✓ Fish: omena (eat 3-4 tablespoons daily), tilapia, sardines
✓ Eggs: 2-3 per day
✓ Lentils (dengu) and beans (maharagwe) — 1 cup cooked per day
✓ Milk (maziwa) and yoghurt (mtindi) at every meal

CALCIUM (bone grows into the hip implant — takes 3-6 months):
✓ Milk (maziwa): 3 glasses per day
✓ Omena (dried small fish): HIGH CALCIUM — eat daily
✓ Yoghurt (mtindi): 2 portions daily
✓ Sukuma wiki (kale): calcium + Vitamin K
✓ Dark green vegetables: spinach (mchicha), broccoli

ANTI-INFLAMMATORY (reduces post-op swelling):
✓ Fish 3x per week (omega-3)
✓ Turmeric (binzari ya njano) in cooking daily
✓ Ginger (tangawizi) in tea

FOR SICKLE CELL PATIENTS:
✓ 3 LITRES of water per day — CRITICAL to prevent sickle cell crisis
✓ Warm fluids encouraged (cold can trigger crisis)
✓ Iron-rich foods: omena, lentils, spinach
✓ Folic acid foods: dark green vegetables, beans
✓ Avoid alcohol completely — it caused the AVN in the first place

AVOID:
✗ Alcohol — ESPECIALLY if AVN was alcohol-related (will damage the new hip too)
✗ Smoking — impairs bone healing and implant integration
✗ Inactivity — hip physiotherapy is essential, attend all sessions""",

        "nutrients_research": """KEY NUTRIENTS FOR HIP REPLACEMENT RECOVERY

• PROTEIN (2.0g/kg/day) — same as knee replacement
• CALCIUM (1200mg/day) — implant integration, bone strength
• VITAMIN D3 — calcium absorption
• IRON — especially critical for sickle cell patients
• HYDRATION — 3 litres/day for sickle cell patients, 2 litres for others
• OMEGA-3 — anti-inflammatory
• FOLIC ACID — sickle cell patients (supports red cell production)
  Sources: sukuma wiki, spinach, beans, fortified uji

RESEARCH EVIDENCE:
- Total joint replacement in sub-Saharan Africa (PMC, 2019): AVN most common indication for THR in SSA. HIV comorbidity in up to 33% of patients. Outcomes comparable to high-income settings with skilled surgeons. Harris Hip Score improves from 28 to 85.""",
    },

    # ─── MASTECTOMY ──────────────────────────────────────────────────────────
    {
        "name": "Mastectomy",
        "code": "MAST",
        "specialty": "Surgical Oncology",

        "overview": """MASTECTOMY — OVERVIEW AND KENYA CONTEXT

Mastectomy is the surgical removal of the breast, primarily performed for breast cancer. In Kenya and sub-Saharan Africa, modified radical mastectomy (MRM) is performed in 64-67% of breast cancer cases — much higher than in high-income countries — because patients present at more advanced stages (Stage III-IV) due to delayed diagnosis.

THE SITUATION IN KENYA:
- Fear of mastectomy is a significant barrier to treatment in Kenya and SSA — women delay seeking care
- Breast cancer is the most common cancer in Kenyan women
- Most surgeries performed by general surgeons rather than specialist oncosurgeons
- The 5-year survival rate does not exceed 60% in any African LMIC
- Dr Miriam Mutebi (Aga Khan University Hospital Nairobi) is a leading advocate for quality breast cancer surgery in Africa
- Turnaround to surgery after diagnosis: 1-5 months in Kenya, with 30-32% of patients paying out of pocket

TYPES OF MASTECTOMY:
- Modified radical mastectomy (MRM): Breast + axillary lymph nodes removed. Most common in Kenya.
- Simple (total) mastectomy: Breast only, no lymph nodes.
- Skin-sparing or nipple-sparing mastectomy: Preserves skin/nipple for reconstruction. Available at Aga Khan, Nairobi Hospital.
- Breast-conserving surgery (lumpectomy): Only tumour removed. Available in 15-26% of African cases (mainly early-stage cancers).""",

        "procedure": """MASTECTOMY — SURGICAL PROCEDURE

MODIFIED RADICAL MASTECTOMY (MRM):
1. General anaesthesia
2. Elliptical incision around the breast (includes areola and nipple)
3. Skin flaps raised (skin elevated from underlying breast tissue)
4. Breast tissue dissected from chest wall (pectoralis major muscle)
5. Axillary lymph node dissection (ALND) — lymph nodes under arm removed for staging
6. Haemostasis secured
7. One or two drains placed
8. Skin closed in layers

Duration: 2-4 hours

SKIN-SPARING / NIPPLE-SPARING WITH RECONSTRUCTION:
Same mastectomy steps but with skin preservation. Implant or tissue expander inserted immediately for reconstruction. Available only at tertiary centres in Kenya.

WHAT TO EXPECT:
- 2-4 day hospital stay
- Two drains under arm (removed when output <30ml/day — usually Day 3-7)
- Significant chest/arm pain Day 1-5
- Arm on operated side may feel tight or weak
- Numbness or tingling in arm and chest — nerves disrupted
- Seroma (fluid collection) often develops under the wound after drains removed — common""",

        "complications": """MASTECTOMY — COMPLICATIONS AND WARNING SIGNS

SERIOUS COMPLICATIONS:
- Seroma: Fluid collection under the wound after drains removed. Very common — affects 15-85% of patients. Signs: soft bulge under wound, feeling of fullness. Managed by aspiration (draining with needle) in clinic. NOT dangerous, but needs attention.
- Lymphoedema: Chronic arm swelling after lymph node removal. Can develop weeks to years after surgery. Risk is lifelong. Signs: arm feels heavy, swollen, tight. Requires specialist lymphoedema therapy.
- Wound infection: Fever, redness, warmth, discharge from wound. Requires antibiotics. Can progress to wound dehiscence (opening).
- Flap necrosis: Skin flap loses blood supply and dies. Wound turns black. Requires wound care, sometimes revision surgery.
- Phantom breast pain: Sensation of breast pain despite breast removal. Common, can be managed.
- Psychological impact: Depression, anxiety, body image distress, relationship changes. VERY SIGNIFICANT in Kenyan women — stigma around mastectomy is substantial. Mental health support is part of treatment.

ONGOING CANCER MONITORING:
- Attend all oncology follow-up appointments
- Report any new lumps or changes in the remaining breast, axilla, or chest wall
- Bone pain (possible metastasis)
- Persistent cough or breathlessness (possible chest metastasis)

ARM CARE AFTER LYMPH NODE REMOVAL:
- Avoid blood pressure cuffs, blood tests, injections in the affected arm (lymphoedema risk)
- Protect the arm from cuts and infection (immune function reduced)
- No heavy lifting (>5kg) for 6 weeks""",

        "diet_preop": """PRE-OPERATIVE DIET FOR MASTECTOMY

2-4 WEEKS BEFORE SURGERY:
Many breast cancer patients have poor nutritional status due to the disease itself. Correcting this before surgery reduces complications.

✓ CORRECT MALNUTRITION FIRST:
  - Eat 3 main meals + 2 snacks per day
  - High-calorie if underweight: add groundnut butter (siagi ya karanga) to uji, use whole milk (maziwa kamili)
  - If eating is difficult: oral nutritional supplements (Ensure, Fresubin)

✓ IMMUNONUTRITION 5-7 DAYS BEFORE SURGERY (reduces infectious complications):
  Arginine, omega-3, and antioxidants. Available in specific formulas (Oral Impact, Fresubin) or foods:
  - Omega-3: sardines, mackerel, omena — eat daily
  - Antioxidants: dark green vegetables, tomatoes, oranges
  - Arginine: found in pumpkin seeds, fish, lean meat, legumes

✓ IRON SUPPLEMENTATION (anaemia common with cancer):
  - Liver (ini), omena, lentils, spinach with Vitamin C

✓ HIGH-PROTEIN (1.5g/kg/day):
  - Eggs, chicken, fish, beans, milk, yoghurt

STANDARD ERAS FASTING:
- Apple juice 500ml evening before
- Apple juice 250ml 2 hours before
- Nothing after that""",

        "diet_postop": """POST-OPERATIVE DIET AFTER MASTECTOMY — DAY BY DAY

EARLY DAYS (Day 0-3):
✓ Clear liquids 4 hours post-op
✓ Progress to full diet on Day 1 — early nutrition critical for healing

WEEK 1-2 (Wound healing focus):
✓ HIGH-PROTEIN (1.5-2.0g/kg/day) — essential for tissue repair
  Eggs, fish, chicken, beans, lentils, milk
✓ Anti-cancer foods: berries (matunda ya damu), cruciferous vegetables, tomatoes, green tea
✓ Small frequent meals if nausea from anaesthesia

IF CHEMOTHERAPY FOLLOWS SURGERY:
✓ HIGH PROTEIN (prevents muscle wasting during chemo): 1.5-2g/kg/day
✓ ANTI-NAUSEA foods: ginger tea (tangawizi), plain rice, toast, bananas
✓ SMALL FREQUENT MEALS: nausea from chemotherapy is worse with empty stomach
✓ Stay hydrated (2+ litres) — chemotherapy is nephrotoxic (kidney toxic if dehydrated)
✓ AVOID raw foods (salads, unwashed fruits) if neutropenic (low white cells — infection risk)

IF HORMONE THERAPY (AROMATASE INHIBITORS) FOLLOWS:
Aromatase inhibitors can cause bone loss (osteoporosis):
✓ CALCIUM 1200mg/day: milk (maziwa), yoghurt (mtindi), omena, fortified foods
✓ VITAMIN D3: sun exposure + fish + supplement

ANTI-CANCER DIETARY APPROACH (LONG-TERM):
✓ Berries and colourful fruits (antioxidants fight cancer recurrence)
✓ Cruciferous vegetables: SUKUMA WIKI (kale), broccoli, cabbage — support oestrogen metabolism
✓ Tomatoes (lycopene) — anti-cancer properties
✓ Green tea (chai ya kijani): gentle anti-cancer properties
✓ Omega-3: fish 3x per week
✓ Soy (maharagwe ya soya) and flaxseed (ufuta): phytoestrogens — modest benefit for hormone-sensitive cancers
✗ AVOID: alcohol (increases breast cancer recurrence risk significantly)
✗ AVOID: processed meats (ham, sausage)
✗ AVOID: excessive red meat

LYMPHOEDEMA DIET:
✓ LOW SODIUM (<2g/day) — sodium worsens lymphoedema swelling
✓ Anti-inflammatory diet
✓ Weight management — obesity worsens lymphoedema""",

        "nutrients_research": """KEY NUTRIENTS FOR MASTECTOMY RECOVERY

• PROTEIN (1.5-2.0g/kg/day) — wound healing, immune function, muscle preservation during cancer treatment
• OMEGA-3 — anti-inflammatory, anti-cancer, reduces chemotherapy side effects
  Sources: sardines, mackerel, omena, salmon
• ANTIOXIDANTS (Vitamin C, E, Beta-carotene) — neutralise free radicals from cancer and chemotherapy
• CALCIUM + VITAMIN D — essential if on aromatase inhibitors (bone protection)
• IRON — anaemia is common in cancer patients
• LOW SODIUM — reduces lymphoedema
• AVOID ALCOHOL — directly increases breast cancer recurrence risk

RESEARCH EVIDENCE:
- Surgical management of breast cancer in Africa (JCO Global Oncology, 2017): MRM >50-90% in Africa; breast-conserving surgery rare; stage III-IV most common presentation.
- Real-world breast cancer challenges in SSA (BMJ Open/PMC, 2021): 862 patients; 64-67% MRM; 1-5 month delay to surgery; 30-32% paying out of pocket in Kenya.
- Quality of breast cancer surgery in Africa (UICC/Mutebi 2025): Most cancer surgeries by general surgeons in Kenya. Need for specialised oncosurgery training.""",
    },

    # ─── THYROIDECTOMY ───────────────────────────────────────────────────────
    {
        "name": "Thyroidectomy",
        "code": "THYROID",
        "specialty": "Endocrine Surgery",

        "overview": """THYROIDECTOMY — OVERVIEW AND KENYA CONTEXT

Thyroidectomy is the surgical removal of all or part of the thyroid gland (located in the front of the neck). In East African highland regions, goitre (enlarged thyroid due to iodine deficiency) remains prevalent.

TYPES:
- Total thyroidectomy: entire thyroid removed (for cancer, Graves' disease, large goitre)
- Lobectomy: one half removed (for single suspicious nodule)
- Subtotal: most of thyroid removed, small remnant left

KENYA-SPECIFIC CONTEXT:
- Iodine deficiency goitre is common in highland areas (Rift Valley, Mount Kenya region)
- Thyroid cancer (papillary type most common) is increasing in Africa
- Kenyan surgeons at the Annals of African Surgery have published on drain use and anaesthesia approaches for thyroidectomy
- Surgery performed at KNH, Nairobi Hospital, Aga Khan, and county hospitals

RECOVERY TIMELINE:
- Hospital stay: 2-3 days
- Return to light activities: 1-2 weeks
- Neck stiffness and discomfort: 2-4 weeks
- Voice changes: usually temporary, resolves within weeks
- Lifelong levothyroxine medication if total thyroidectomy""",

        "procedure": """THYROIDECTOMY — SURGICAL PROCEDURE

1. General anaesthesia (patient on back, neck extended)
2. Collar (Kocher) incision: 5-8cm curved incision in neck crease
3. Subplatysmal flaps raised: skin and muscle elevated to expose thyroid
4. Recurrent laryngeal nerves (RLN) identified and preserved — CRITICAL to prevent hoarseness
5. Parathyroid glands identified and preserved — CRITICAL to prevent hypocalcaemia
6. Thyroid blood vessels ligated and divided
7. Thyroid dissected from trachea
8. Specimen removed
9. Drain placed (evidence from Kenya suggests NOT using drain routinely)
10. Wound closed in layers
11. Scar hidden in neck crease

INTRAOPERATIVE NERVE MONITORING (IONM):
In high-resource settings, a nerve monitor is used to protect the RLN. Available at Aga Khan, Nairobi Hospital.

Duration: 1-3 hours

WHAT TO EXPECT:
- Mild to moderate neck pain and stiffness (gets better Day 2-3)
- Voice may sound hoarse or weak — usually temporary (weeks)
- Low-grade fever first 24 hours — normal
- Monitor for: neck swelling (haematoma risk in first 6 hours)""",

        "complications": """THYROIDECTOMY — COMPLICATIONS AND WARNING SIGNS

SERIOUS COMPLICATIONS (URGENT ATTENTION):
- Haematoma (neck blood clot): Can compress the airway. Signs: rapidly enlarging neck swelling, difficulty breathing, stridor. EMERGENCY — go to hospital IMMEDIATELY. This can be life-threatening.
- Hypoparathyroidism: Most common complication. Parathyroid glands control calcium. If injured or removed, calcium levels drop. Signs: tingling lips or fingertips, muscle cramps, tetany (muscle spasms), anxiety. Needs immediate calcium supplementation.
- Recurrent laryngeal nerve (RLN) injury: Can cause permanent hoarseness or (if both sides) breathing difficulty. Usually temporary if nerves are intact.
- Hypothyroidism: After total thyroidectomy, the body has no thyroid hormone. Requires lifelong levothyroxine replacement. Signs without treatment: fatigue, weight gain, cold intolerance, slow pulse.
- Thyroid storm (rare): Dangerous surge of thyroid hormones, usually in uncontrolled hyperthyroid patients. Signs: very rapid heart rate, high fever, confusion. Prevented with pre-operative medication.

WATCH AT HOME:
- Rapid swelling of the neck — go to emergency immediately
- Tingling or numbness in lips or fingers — calcium problem — take calcium tablets and go to hospital
- Muscle cramps in hands or feet
- Difficulty swallowing that is worsening
- Voice that is getting worse (not better) over 2 weeks
- Fever above 38.5°C after Day 3

LIFELONG MEDICATION AFTER TOTAL THYROIDECTOMY:
- Levothyroxine (Eltroxin) EVERY MORNING on an empty stomach, 30-60 minutes before food
- Take with water only — do not take with milk, tea, calcium, iron (all reduce absorption)
- Blood tests (TSH level) every 3-6 months""",

        "diet_preop": """PRE-OPERATIVE DIET FOR THYROIDECTOMY

FOR GRAVES' DISEASE PATIENTS (hyperthyroid):
- Iodine restriction 2 weeks before surgery (reduces thyroid vascularity)
- Avoid iodine-rich foods: seaweed, iodised salt in large quantities, contrast media
- Lugol's iodine drops will be given by doctor 10-14 days before surgery

HIGH-CALCIUM DIET (build calcium stores before surgery):
The parathyroid glands are AT RISK during thyroidectomy. Pre-loading calcium stores is protective.
✓ Milk (maziwa): 3 glasses per day
✓ Yoghurt (mtindi): 2 portions per day
✓ Omena (dried small fish): eat daily — very high calcium
✓ Dark green vegetables: sukuma wiki, spinach

STANDARD FASTING:
- Normal food up to 6 hours before
- Clear liquids up to 2 hours before
- Nothing after that""",

        "diet_postop": """POST-OPERATIVE DIET AFTER THYROIDECTOMY — DAY BY DAY

DAY 0 (Surgery day):
✓ Clear liquids when awake — water, broth, ORS
✓ Soft swallowing only — neck incision causes discomfort with swallowing
✓ Small sips, sit upright

DAY 1:
✓ Soft diet — nothing hard that requires vigorous chewing or swallowing
✓ Uji wa unga (thin porridge)
✓ Soft scrambled eggs
✓ Smooth yoghurt (mtindi laini)
✓ Soup with soft pieces
✓ Ripe banana, soft mango pieces
✓ Avoid: bread, chapati, ugali (hard to swallow with neck stiffness)

CRITICAL AFTER SURGERY — HIGH CALCIUM DIET:
After total thyroidectomy, the parathyroid glands may be temporarily stunned → calcium drops.
✓ CALCIUM-RICH FOODS EVERY MEAL:
  - Milk (maziwa): 3+ glasses per day
  - Yoghurt (mtindi): at every meal
  - Omena (dried small fish): 3-4 tablespoons per day (extremely high calcium)
  - Sukuma wiki, spinach
  - Calcium carbonate tablets if prescribed — take with food
✓ VITAMIN D3: helps absorb calcium
  - 30 minutes morning sunlight
  - Fatty fish: sardines, mackerel, omena
  - Supplement if prescribed

LIFELONG DIETARY RULES AFTER THYROIDECTOMY:
✓ LEVOTHYROXINE TIMING: Take on EMPTY STOMACH, 30-60 minutes before breakfast. Then wait before eating or drinking.
  ✗ Do NOT take with: milk, tea, coffee, calcium supplements, iron supplements (all reduce absorption)
  ✓ Take with: plain water only

✓ IODINE-ADEQUATE DIET (if thyroid cancer NOT present):
  - Use iodised salt for cooking
  - Eat fish and seafood regularly (natural iodine)
  - Avoid goitrogens in large quantities: raw cabbage, raw cassava (soak/cook thoroughly first)

✓ IF THYROID CANCER: Iodine-RESTRICTED diet may be prescribed temporarily for radioiodine treatment — your oncologist will advise.

AVOID GOITROGENS (large raw amounts can block thyroid):
- Raw cabbage, kale, broccoli — COOK THOROUGHLY (cooking destroys goitrogens)
- Raw cassava leaves (soak, then boil thoroughly)
- These foods ARE FINE when cooked and in normal portions""",

        "nutrients_research": """KEY NUTRIENTS FOR THYROIDECTOMY RECOVERY

• CALCIUM — CRITICAL post-thyroidectomy (parathyroid injury risk)
  Target: 1200-1500mg/day post-op
  Sources: milk (maziwa), yoghurt (mtindi), OMENA (highest calcium food in Kenya per gram), sukuma wiki

• VITAMIN D3 — essential for calcium absorption
  Target: 800-2000 IU/day
  Sources: sunlight, fatty fish (omena, sardines)

• IODINE — for patients without thyroid cancer (thyroid hormone production)
  Sources: iodised salt, fish, seafood

• SELENIUM — thyroid function enzyme (if thyroid remnant remains after lobectomy)
  Sources: Brazil nuts, fish, meat, eggs

• PROTEIN — wound healing
  Sources: eggs, fish, chicken, milk, beans

RESEARCH EVIDENCE:
- Kenyan data: Drains after thyroidectomy for benign disease associated with more pain, wound infection and prolonged stay (Annals of African Surgery, 2022). Recommends against routine drain use.
- Role of infiltrative local anaesthesia in thyroidectomy (Annals of African Surgery, Ojuka, Saidi, Rere 2022): Local anaesthesia is effective for pain management in thyroidectomy at Nairobi-based hospitals.""",
    },

    # ─── MYOMECTOMY ──────────────────────────────────────────────────────────
    {
        "name": "Myomectomy",
        "code": "MYOM",
        "specialty": "Gynaecology",

        "overview": """MYOMECTOMY — OVERVIEW AND KENYA CONTEXT

Myomectomy is the surgical removal of uterine fibroids (myomas) while preserving the uterus. It is the preferred surgery for women who want to maintain their fertility or keep their uterus.

FIBROIDS IN KENYA — WHY THIS IS IMPORTANT:
- Uterine fibroids affect up to 70-80% of Black women by age 50
- Fibroids are the SINGLE MOST COMMON indication for both myomectomy and hysterectomy in Kenya
- Symptoms: heavy menstrual bleeding (many women in Kenya are severely anaemic as a result), pelvic pressure/pain, frequent urination, difficulty getting pregnant
- Many Kenyan women live with severe anaemia for years before receiving surgery

APPROACHES IN KENYA:
- Open (laparotomy) myomectomy: Most common. Midline or Pfannenstiel incision. Suitable for large or multiple fibroids.
- Laparoscopic myomectomy: Available at private hospitals (Aga Khan, Nairobi Hospital). Faster recovery.
- Hysteroscopic myomectomy: For fibroids inside the uterine cavity (submucosal). No abdominal incision.

RECOVERY TIMELINE:
- Open: 4-7 day hospital stay, full recovery 6-8 weeks
- Laparoscopic: 1-2 day hospital stay, full recovery 2-4 weeks
- Return to normal activities (light): 2 weeks (laparoscopic), 4 weeks (open)
- FERTILITY: Attempt pregnancy only after 3-6 months (uterus must heal)
- Fibroid recurrence: up to 50% over 10 years — fibroids can grow back""",

        "procedure": """MYOMECTOMY — SURGICAL PROCEDURE

OPEN MYOMECTOMY (most common in Kenya):
1. General or spinal anaesthesia
2. Pfannenstiel or midline incision
3. Uterus exposed and assessed — all fibroids mapped
4. Vasopressin injected into uterine muscle (reduces bleeding)
5. Incision made directly over each fibroid
6. Fibroid shelled out (enucleated) from the uterine muscle
7. Uterine muscle closed in multiple layers with absorbable sutures
8. Anti-adhesion barrier placed over suture lines (prevents adhesions/tubal blockage)
9. Abdominal closure
10. Drain placed if extensive surgery

HYSTEROSCOPIC MYOMECTOMY (submucosal fibroids):
1. No abdominal incision — hysteroscope inserted through the cervix
2. Fluid distends the uterine cavity
3. Resectoscope used to shave the fibroid from the inside of the uterus
4. Day surgery — home same day

Duration: Open 1-4 hours (depends on number/size of fibroids), Hysteroscopic 30-60 minutes

WHAT TO EXPECT AFTER OPEN MYOMECTOMY:
- Significant pain Day 1-5
- Vaginal bleeding (lighter than period) for 1-2 weeks
- Fatigue and weakness (especially if anaemic pre-op)
- Bloating, gas, constipation for 1 week""",

        "complications": """MYOMECTOMY — COMPLICATIONS AND WARNING SIGNS

SERIOUS COMPLICATIONS:
- Haemorrhage: Major blood loss is the main intraoperative risk with myomectomy. Fibroids have a rich blood supply. Risk of hysterectomy if bleeding cannot be controlled. Signs of post-op anaemia: pallor, weakness, rapid heart rate, dizziness.
- Adhesion formation: Scar tissue can form around the fallopian tubes and ovaries after myomectomy, affecting fertility. Anti-adhesion barriers reduce this risk.
- Uterine scar rupture in subsequent pregnancy: If uterine muscle is entered deeply during fibroid removal, the scar may rupture during a future labour. Usually managed with planned C-section at 37-38 weeks.
- Fibroid recurrence: Up to 50% over 10 years. New fibroids can grow from microscopic seedlings left behind.
- Wound infection: Fever, wound redness, discharge. Higher risk if very anaemic or large blood loss.

EMERGENCY SIGNS:
- Haemoglobin drop (feels faint, heart racing) — go to hospital
- Fever above 38.5°C after Day 3
- Abdominal pain worsening after Day 5 (should be improving)
- Heavy vaginal bleeding (soaking pad every hour) — EMERGENCY
- Signs of internal bleeding: severe abdominal distension, rapid deterioration in wellbeing""",

        "diet_preop": """PRE-OPERATIVE DIET FOR MYOMECTOMY

CORRECTING ANAEMIA — THE MOST IMPORTANT PRE-OP GOAL:
Fibroids cause heavy menstrual bleeding → most patients are iron-deficient anaemic before surgery. Correcting haemoglobin BEFORE surgery significantly reduces transfusion risk.

✓ HIGH-IRON DIET (start immediately, ideally 2-4 weeks before surgery):
  Best iron sources in Kenya:
  - Liver (ini): The highest iron food available. Eat 2-3 times per week.
  - Omena (small dried fish): Very iron-rich + high calcium
  - Red meat (nyama nyekundu): beef, goat — 3-4 times per week
  - Lentils (dengu): 1 cup cooked per day
  - Spinach (mchicha): large portion every day
  - Maharagwe (beans): high iron
  - Fortified uji (porridge): check label for iron content

✓ VITAMIN C WITH EVERY IRON-RICH MEAL (increases iron absorption 3-4 times):
  - Orange juice (maji ya chungwa): glass with each meal
  - Tomatoes (nyanya): add to every plate
  - Squeeze lemon on food
  DO NOT have tea or coffee within 1 hour of iron-rich meals (blocks absorption)

✓ IRON SUPPLEMENTS: Your doctor will likely prescribe ferrous sulfate. Take with orange juice, not tea.

GnRH AGONIST (shrinks fibroids pre-op):
If prescribed: These cause temporary menopause → risk of bone loss. Take CALCIUM + VITAMIN D during this period.

STANDARD ERAS FASTING:
- Normal meal the evening before
- Apple juice 500ml evening before, 250ml 2 hours before
- Nothing after that""",

        "diet_postop": """POST-OPERATIVE DIET AFTER MYOMECTOMY — DAY BY DAY

KEY PRIORITIES:
1. REBUILD IRON STORES (surgery caused further blood loss)
2. SUPPORT UTERINE HEALING (high protein)
3. PREVENT CONSTIPATION (straining risks uterine suture line)
4. ANTI-FIBROID NUTRITION LONG-TERM (reduce oestrogen to slow regrowth)

DAYS 0-1:
✓ Clear liquids → progress to soft diet (same as C-section/laparotomy protocol)

DAYS 2-7:
✓ HIGH-IRON DIET RESUMES IMMEDIATELY:
  - Liver (ini), omena, lentils, spinach, red meat
  - Always with Vitamin C (oranges, tomatoes, lemon)
✓ HIGH PROTEIN (1.5g/kg/day) for uterine muscle repair:
  - Eggs, chicken, fish, milk, yoghurt, beans
✓ 2 litres of water per day
✗ AVOID constipation triggers; eat enough fibre

LONG-TERM — ANTI-FIBROID NUTRITION APPROACH:
Fibroids are driven by oestrogen. Diet can modulate oestrogen levels:

✓ CRUCIFEROUS VEGETABLES — support liver oestrogen metabolism:
  - SUKUMA WIKI (kale): eat daily
  - Broccoli, cabbage (cooked)
  - Spinach (mchicha)

✓ REDUCE PRO-OESTROGENIC FOODS:
  ✗ Reduce red meat (promotes inflammation and oestrogen)
  ✗ Reduce alcohol (liver metabolises oestrogen — alcohol impairs this)
  ✗ Reduce full-fat dairy and high-fat foods

✓ FLAXSEED (UFUTA WA MBEGU) and SOY:
  - Phytoestrogens are weak oestrogens that compete with the body's own oestrogen
  - Modest evidence they slow fibroid growth
  - Add flaxseed to uji, yoghurt, or smoothies

✓ VITAMIN D:
  - Deficiency is directly linked to higher fibroid risk
  - Sun exposure 30 minutes daily
  - Fatty fish, eggs, Vitamin D supplement

✓ CALCIUM + VITAMIN D:
  - If GnRH agonist was used pre-op (causes temporary bone loss)
  - Milk, yoghurt, omena, sukuma wiki""",

        "nutrients_research": """KEY NUTRIENTS FOR MYOMECTOMY RECOVERY

• IRON — most critical nutrient. Fibroids cause chronic blood loss. Surgery adds to this.
  Sources: liver (ini), omena, lentils (dengu), spinach, maharagwe, red meat

• VITAMIN C — iron absorption, collagen synthesis for uterine healing
  Sources: oranges (machungwa), tomatoes, guava (mapera), lemon

• PROTEIN (1.5g/kg/day) — uterine muscle repair. The uterus is extensively sutured.
  Sources: eggs, chicken, fish, milk, beans

• CALCIUM + VITAMIN D — if GnRH agonist used (causes bone loss)
  Sources: omena, milk, yoghurt, sukuma wiki, sunlight

• VITAMIN D — linked to fibroid risk reduction
  Deficiency common in Kenya despite abundant sunshine (sunscreen, skin pigmentation)

• FIBRE — prevents constipation and straining on uterine suture line
  Sources: sukuma wiki, fruits, whole grain ugali, beans

RESEARCH EVIDENCE:
- Uterine fibroid burden in Kenya (multiple African gynaecological studies, 2023): Fibroids affect 70-80% of Black women. Most common indication for gynaecological surgery in Kenya.
- ERAS for gynaecological surgery including myomectomy (ESPEN/Clinical Nutrition 2021): ERAS protocols validated for gynaecological surgery with early feeding and immunonutrition pre-op.""",
    },

    # ─── LAPAROTOMY ──────────────────────────────────────────────────────────
    {
        "name": "Laparotomy (Exploratory)",
        "code": "LAPAROTOMY",
        "specialty": "General Surgery",

        "overview": """EXPLORATORY LAPAROTOMY — OVERVIEW AND KENYA CONTEXT

An exploratory laparotomy is a large abdominal incision (midline or transverse) performed to explore the abdominal cavity when the cause of a patient's condition is unknown and less invasive methods are insufficient or unavailable.

IN KENYA AND SUB-SAHARAN AFRICA:
Laparotomy is a critical operation in East Africa where advanced imaging (CT scanning) and laparoscopy are limited in many facilities. It is often a life-saving procedure for:
- Peritonitis (pus/infection throughout the abdomen from perforated bowel/stomach)
- Trauma (road traffic accidents — very common in Kenya)
- Bowel obstruction that won't resolve with conservative management
- Ruptured ectopic pregnancy (gynaecological emergency)
- Post-operative complications

The Surgical Apgar Score (developed by Dullo et al. using Kenyan data, Annals of African Surgery) predicts post-laparotomy complications.

RECOVERY TIMELINE:
- Hospital stay: 5-14 days (depends on what was found and repaired)
- Drain removal: Day 3-7 (if placed)
- Return to light activities: 4-6 weeks
- Full recovery: 6-12 weeks
- Heavy lifting: no earlier than 3 months""",

        "procedure": """LAPAROTOMY — SURGICAL PROCEDURE

INCISION TYPES:
- Midline incision: Umbilicus to pubis or xiphoid (full length). Fastest, widest access. Used for emergencies.
- Transverse (Pfannenstiel): For pelvic surgery. Better cosmetic outcome.

PROCEDURE:
1. General anaesthesia (may be emergency — rapid sequence induction)
2. Midline incision from below xiphoid to below umbilicus (or full length if needed)
3. Peritoneum entered (abdominal cavity opened)
4. Systematic four-quadrant exploration — every organ examined
5. Identification and management of pathology (repair perforated bowel, haemorrhage control, etc.)
6. If bowel resection performed: anastomosis (joining bowel ends) or stoma creation
7. Thorough irrigation with warm saline if contaminated (peritonitis)
8. Drain placed if contaminated or anastomosis performed
9. Mass closure technique preferred for abdominal wall (reduces hernia risk)
10. Skin closed (or left open in contaminated cases to heal secondarily)

Duration: 1-5 hours (variable — depends entirely on what is found)

WHAT TO EXPECT:
- ICU or HDU admission for first 24-48 hours if critically ill
- IV drip and NG tube (stomach drain) often needed
- Significant pain for 5-7 days — IV morphine initially
- No food until bowel wakes up (bowel sounds return, patient passes gas)""",

        "complications": """LAPAROTOMY — COMPLICATIONS AND WARNING SIGNS

SERIOUS COMPLICATIONS:
- Wound dehiscence: Abdominal wound opens (splits open). Layers separate. Signs: serosanguinous (pink/bloody) fluid leaking from wound. Emergency surgical repair needed. More common with contaminated wounds and malnutrition.
- Incisional hernia: Weakness in the scar leads to bulging of abdominal contents. Affects 20-30% of laparotomy patients long-term. Appears as a bulge at the scar site.
- Adhesions → small bowel obstruction: Scar tissue forms after any abdominal surgery. Can cause bowel to kink weeks, months, or years later. Signs: sudden colicky abdominal pain, vomiting, no bowel movements, abdominal distension.
- Intra-abdominal sepsis: Infection in the abdominal cavity. Fever, abdominal pain, raised white cells. May need return to theatre.
- Anastomotic leak: If bowel was joined (anastomosis), the join can leak. Signs: fever, worsening abdominal pain Day 3-5, peritonism. Serious emergency.
- Prolonged ileus: Bowel doesn't wake up after surgery. Signs: no bowel sounds, distended abdomen, vomiting, unable to eat.

EMERGENCY SIGNS:
- Wound edges separating (pink fluid soaking dressing)
- Fever above 38.5°C after Day 5
- Worsening abdominal pain after initial improvement
- Vomiting, distension, no gas — possible bowel obstruction
- Rapid deterioration in overall condition""",

        "diet_preop": """PRE-OPERATIVE DIET FOR LAPAROTOMY

EMERGENCY LAPAROTOMY (most common):
- NOTHING BY MOUTH IMMEDIATELY
- Tell staff when you last ate — important for anaesthesia safety
- IV fluids will be started

ELECTIVE LAPAROTOMY (planned surgery):
✓ NUTRITIONAL OPTIMISATION: If malnourished, 5-7 days of high-protein, high-calorie nutrition before surgery.
  - Oral nutritional supplements (Ensure, Fresubin) if eating is poor
  - Eggs, milk, chicken, fish, lentils daily
✓ IMMUNONUTRITION 5 days before (if nutritional risk): arginine, omega-3, antioxidants
✓ ERAS carbohydrate loading: Apple juice 500ml evening before, 250ml 2 hours before
✓ CORRECT ANAEMIA: Iron-rich foods + Vitamin C for 2+ weeks pre-op""",

        "diet_postop": """POST-OPERATIVE DIET AFTER LAPAROTOMY — CRITICAL PRINCIPLES

The golden rule after laparotomy is: EAT EARLY AND BUILD UP GRADUALLY.
Early enteral (oral) feeding within 24-48 hours reduces complications, shortens hospital stay, and improves outcomes. This is supported by all current ERAS guidelines.

HOWEVER: Never force oral intake. Wait for bowel sounds to return and for the patient to pass gas (flatus). Without bowel function, eating causes distension, vomiting, and aspiration risk.

PHASE 1 — NPO (Nil by mouth until bowel wakes up):
✓ IV fluids and electrolytes only
✓ NG tube for stomach decompression if needed
✓ Mouth care (ice chips to moisten lips)
Expect this phase to last: 1-3 days for minor laparotomy, 3-5 days for contaminated/bowel cases

PHASE 2 — Clear liquids (bowel sounds present, patient has passed gas):
✓ Water (maji): start with small sips
✓ Clear broth (mchuzi wazi): chicken or vegetable
✓ ORS (oral rehydration salts)
✓ Weak tea
✓ Small sips every 30 minutes

PHASE 3 — Soft diet (tolerating liquids well):
✓ Thin uji (porridge) — excellent first solid food
✓ Boiled potato or mashed potato
✓ Soft boiled egg
✓ Rice with clear soup
✓ Ripe banana
✓ Monitor for vomiting, distension — stop and return to liquids if these occur

PHASE 4 — High-protein full diet (bowel fully functional):
✓ HIGH-PROTEIN (1.5g/kg/day): eggs, chicken, fish, beans, milk, lentils
✓ VITAMIN C: oranges, tomatoes — wound healing
✓ ZINC: meat, pumpkin seeds
✓ HIGH-CALORIE if malnourished: groundnut butter (siagi ya karanga) in uji, whole milk
✓ Gradually increase fibre as bowel tolerates
✓ 2+ litres of water per day

IF ANASTOMOSIS WAS PERFORMED (bowel joined):
Bowel rest protocol — stricter and slower progression. The join needs time to heal.
Do NOT rush to normal diet — risk of anastomotic leak is real in Days 3-7.
Follow surgeon's specific dietary instructions.

IF BOWEL STOMA (colostomy/ileostomy) WAS FORMED:
A special dietary protocol applies — the stoma team will advise.
Generally: high protein, adequate hydration, avoid foods causing blockage initially.""",

        "nutrients_research": """KEY NUTRIENTS FOR LAPAROTOMY RECOVERY

• PROTEIN (1.5g/kg/day) — wound repair, immune function, prevention of muscle wasting
  Sources: eggs, chicken, fish, omena, lentils, milk, beans

• GLUTAMINE — gut-specific amino acid. Reduces gut permeability after major abdominal surgery.
  Sources: eggs, fish, meat, beans, spinach

• ZINC — wound healing enzymes, especially important for large incisions
  Sources: red meat, chicken, pumpkin seeds, legumes

• VITAMIN A — epithelial (skin/gut lining) repair
  Sources: liver (ini), eggs, sweet potato (viazi vitamu), carrots, dark greens

• ELECTROLYTES (sodium, potassium, magnesium) — lost with vomiting, NG drainage, ileus
  Sources: ORS, bananas (potassium), avocado, sweet potato

• VITAMIN C — collagen for large wound closure
  Sources: oranges, tomatoes, guava

RESEARCH EVIDENCE:
- Surgical Apgar Score predicts post-laparotomy complications (Annals of African Surgery, 2022): Dullo et al.; Kenyan data — Surgical Apgar Score validated for SSA laparotomy outcomes.
- Closure methods for laparotomy incisions (Cochrane 2017): Mass closure with slowly absorbable suture reduces incisional hernia risk. Relevant for reducing the 20-30% incisional hernia rate.""",
    },

    # ─── PROSTATECTOMY ───────────────────────────────────────────────────────
    {
        "name": "Prostatectomy",
        "code": "PROSTA",
        "specialty": "Urology",

        "overview": """PROSTATECTOMY — OVERVIEW AND KENYA CONTEXT

Prostatectomy is the surgical removal of part (simple) or all (radical) of the prostate gland.
- Radical prostatectomy (RP): Treats localised prostate cancer. Entire prostate + seminal vesicles removed.
- Simple prostatectomy: Treats benign prostatic hyperplasia (BPH) — enlarged prostate causing urinary obstruction.

IN KENYA:
- Prostate cancer is increasingly recognised in East Africa as life expectancy improves
- Aga Khan University Hospital Nairobi offers robotic prostatectomy (da Vinci robot) — the most advanced urology in East Africa
- BPH is extremely common in men over 60 — a major quality-of-life problem
- Simple prostatectomy for BPH performed at KNH, Nairobi Hospital, and county referral hospitals

RECOVERY TIMELINE:
- Catheter in place for 1-2 weeks post-surgery
- Hospital stay: 3-5 days (open), 1-2 days (robotic/laparoscopic)
- Return to light activities: 2-4 weeks
- Full recovery: 6-12 weeks
- Urinary control improvement: continues improving for up to 12 months
- Sexual function recovery: may take 12-24 months""",

        "procedure": """PROSTATECTOMY — SURGICAL PROCEDURE

OPEN RADICAL PROSTATECTOMY (retropubic):
1. Lower midline incision (umbilicus to pubis)
2. Pelvic lymph nodes dissected and sent for analysis
3. Pubic bone approached, space of Retzius developed
4. Prostate dissected from surrounding structures
5. Neurovascular bundles (responsible for erections) preserved if nerve-sparing
6. Prostate + seminal vesicles removed
7. Vesicourethral anastomosis (bladder joined to urethra)
8. Drain placed, catheter inserted
9. Wound closed

ROBOTIC RADICAL PROSTATECTOMY (da Vinci — Aga Khan Hospital):
Same steps as above but performed with robotic precision through 6 small ports.
Superior outcomes for erectile function, continence, and blood loss.

Duration: 2-4 hours

WHAT TO EXPECT:
- Catheter for 7-14 days (takes this long for the vesicourethral anastomosis to heal)
- Significant pelvic pain and discomfort for 5-7 days
- Pink urine (haematuria) for 1-2 weeks — normal
- Urinary incontinence after catheter removed — improves with pelvic floor exercises (Kegel exercises)""",

        "complications": """PROSTATECTOMY — COMPLICATIONS AND WARNING SIGNS

COMMON COMPLICATIONS (often temporary):
- Urinary incontinence: Very common after catheter removed. Most improve over 3-12 months. Pelvic floor exercises (Kegel exercises) are essential — begin as soon as catheter is removed.
- Erectile dysfunction (ED): Nerve-sparing surgery significantly reduces this risk, but ED can affect 30-80% depending on technique and age. Improves over 12-24 months.

SERIOUS COMPLICATIONS:
- Anastomotic leak: The vesicourethral join breaks down. Signs: severe pelvic pain, large urine leak, fever. Requires catheter management or surgery.
- DVT/PE: High risk after pelvic surgery. Calf pain + swelling (DVT). Chest pain + breathlessness (PE — EMERGENCY).
- Anastomotic stricture: Narrowing at the join causes weak urine stream (weeks to months later). Dilated endoscopically.
- Biochemical recurrence of prostate cancer: PSA rises after surgery. Indicates cancer wasn't fully removed. Needs oncology review.
- Lymphocele: Fluid collection in pelvis after lymph node dissection. Signs: pelvic fullness, leg swelling.

CATHETER CARE AT HOME:
- Keep the catheter and bag clean
- Empty bag when half full
- Watch for: fever, foul-smelling urine, sudden inability to pass urine around the catheter (call hospital)
- Do NOT pull on the catheter""",

        "diet_preop": """PRE-OPERATIVE DIET FOR PROSTATECTOMY

PROSTATE-HEALTHY PRE-OP DIET (start weeks before):
✓ Tomatoes (nyanya): lycopene is protective against prostate cancer — especially COOKED tomatoes (cooking concentrates lycopene)
✓ Green tea: gentle prostate protection
✓ Cruciferous vegetables: broccoli, sukuma wiki (kale)
✓ Reduce red and processed meat pre-op

STANDARD ERAS FASTING:
- Apple juice 500ml evening before
- Apple juice 250ml 2 hours before
- Nothing after that""",

        "diet_postop": """POST-OPERATIVE DIET AFTER PROSTATECTOMY — DAY BY DAY

DAYS 0-1:
✓ Clear liquids when awake
✓ Water, broth, ORS, weak tea

DAYS 2-3:
✓ Soft diet: avoid anything requiring straining
✓ Bowel movements create pressure on the anastomosis — PREVENT CONSTIPATION
✓ Boiled eggs, soft fish, rice, banana, soft ugali
✓ HIGH-FIBRE to prevent straining

DAYS 4 ONWARD:
✓ HIGH-FIBRE DIET — CRITICAL (prevents straining which stresses the anastomosis):
  - Sukuma wiki, spinach, fruits, whole grain ugali
  - Stool softeners if needed (lactulose from chemist)
✓ 2-3 LITRES OF WATER PER DAY:
  - Flushes the urinary system
  - Keeps the catheter draining well
  - Reduces urinary tract infection risk
  - Dilutes urine (reduces haematuria)

LONG-TERM PROSTATE HEALTH:
✓ Anti-inflammatory diet long-term (slows cancer recurrence risk):
  - Berries: blueberries, strawberries, raspberries
  - Turmeric (binzari ya njano): daily in cooking
  - Green tea (chai ya kijani): 2-3 cups daily
  - Fatty fish: 3x per week (omega-3)
✓ LYCOPENE-RICH FOODS:
  - COOKED TOMATOES (nyanya za kupika): tomato paste, stewed tomatoes — much better than raw
  - Watermelon (tikiti maji)
  - Guava (mapera): very high lycopene
✓ Limit red meat and processed foods
✗ AVOID alcohol during catheter period and recovery""",

        "nutrients_research": """KEY NUTRIENTS FOR PROSTATECTOMY RECOVERY

• LYCOPENE — antioxidant with anti-prostate cancer properties
  Sources: COOKED tomatoes (nyanya za kupika) — cooking concentrates lycopene 3-4x
  Watermelon, guava, tomato paste

• SELENIUM — prostate protective, enzyme function
  Sources: fish, meat, eggs

• ZINC — prostate health enzyme
  Sources: red meat, pumpkin seeds, legumes

• OMEGA-3 — anti-inflammatory, anti-cancer
  Sources: sardines, mackerel, omena

• FIBRE (25-35g/day) — prevents constipation (protects anastomosis)
  Sources: sukuma wiki, fruits, whole grain ugali

• WATER (2-3 litres/day) — flushes urinary system, reduces infection risk

RESEARCH EVIDENCE:
- Low-cost robotic radical prostatectomy in Kenya (Aga Khan University Hospital 2024): AKUH Nairobi offers robotic prostatectomy — most advanced urology in East Africa.
- Prostate cancer surgical outcomes Kenya (Annals of African Surgery 2022): Increasing prostate cancer burden in sub-Saharan Africa. Surgical outcome data emerging.""",
    },

    # ─── TUBAL LIGATION ──────────────────────────────────────────────────────
    {
        "name": "Tubal Ligation",
        "code": "TUBAL",
        "specialty": "Gynaecology",

        "overview": """TUBAL LIGATION — OVERVIEW AND KENYA CONTEXT

Tubal ligation is a surgical procedure for permanent contraception in women. The fallopian tubes are permanently blocked, cut, or removed to prevent eggs from reaching sperm. It is a key family planning procedure in Kenya's public health system.

IN KENYA:
- Widely performed at county hospitals, KNH, and private hospitals
- Often performed postpartum (within 48 hours of delivery) during or shortly after a C-section (no additional incision needed)
- Interval sterilisation (6+ weeks after delivery) is also common
- Methods used: Pomeroy technique (cut and tie), Filshie clips, bipolar coagulation, salpingectomy (tube removal — becoming preferred as it may reduce ovarian cancer risk)
- Complication rates are low when performed by skilled surgeons

IMPORTANT COUNSELLING POINTS:
- PERMANENT: This procedure should be considered irreversible. Reversal requires complex microsurgery with limited success (~50-80% in best centres).
- Does NOT affect hormones: Ovaries remain, menstrual cycle continues normally, menopause occurs at normal age.
- Does NOT protect against STIs/HIV: Barrier contraception still needed.
- Failure rate: 0.5-1% — small but real chance of pregnancy, and if it occurs, it may be ectopic (in the tube).

RECOVERY TIMELINE:
- Day surgery usually (laparoscopic) or 1-2 days postpartum
- Return to light activities: Day 2-3
- Return to normal activities: 1 week
- Full recovery: 1-2 weeks""",

        "procedure": """TUBAL LIGATION — SURGICAL PROCEDURE

LAPAROSCOPIC (most common for interval sterilisation):
1. 2 small ports (umbilical + lower abdomen)
2. CO₂ inflation
3. Fallopian tubes identified
4. Pomeroy: tubes tied with suture then cut (small section removed)
   OR Filshie clips applied to tubes
   OR Bipolar coagulation (tubes burned)
   OR Salpingectomy (entire tube removed)
5. Ports closed — 2 tiny incisions, dressings only
6. Day surgery — home same day

MINILAPAROTOMY (common for postpartum sterilisation):
1. Small suprapubic incision (2-3cm)
2. Fallopian tubes brought up through incision
3. Pomeroy ligation and resection
4. Wound closed in layers
5. If done at C-section: no additional incision — done through the C-section wound

Duration: 15-30 minutes (standalone), minimal added time at C-section

WHAT TO EXPECT:
- Mild pelvic cramping for 1-2 days (similar to period pain)
- Shoulder tip pain if laparoscopic (trapped CO₂)
- Very quick recovery compared to other surgeries""",

        "complications": """TUBAL LIGATION — COMPLICATIONS AND WARNING SIGNS

RARE BUT POSSIBLE COMPLICATIONS:
- Failure (0.5-1%): The procedure is 99-99.5% effective. If pregnancy occurs, high risk it is ectopic (in the tube). Signs of ectopic pregnancy: one-sided pelvic pain, vaginal bleeding, shoulder tip pain, dizziness — EMERGENCY.
- Bowel or vessel injury (laparoscopic): Very rare. Severe abdominal pain post-surgery. EMERGENCY.
- Anaesthetic complications: Rare with spinal or local anaesthesia.
- Wound infection: Redness, discharge from incision site. Requires antibiotics.
- Regret: Desire to reverse sterilisation. Reversal is complex — counsel before the procedure.

NORMAL SYMPTOMS:
- Mild cramping for 1-3 days (like period pain)
- Spotting for 1-2 days
- Mild shoulder tip pain for 24-48 hours (laparoscopic CO₂)
- Slight fatigue
- Minor bloating""",

        "diet_preop": """PRE-OPERATIVE DIET FOR TUBAL LIGATION

Standard surgical fasting:
- Normal eating up to 6 hours before surgery
- Clear liquids up to 2 hours before
- Nothing after that

If combined with C-section: Follow the C-section pre-operative diet protocol.

If postpartum (within 48 hours of delivery): Normal postpartum diet. Breastfeeding nutrition rules apply (see C-section post-op diet for breastfeeding guidance).""",

        "diet_postop": """POST-OPERATIVE DIET AFTER TUBAL LIGATION — DAY BY DAY

This is a MINOR surgery — dietary recovery is very quick.

DAY 0 (surgery day):
✓ Clear liquids 2-4 hours after procedure (very short surgery)
✓ Light meal when home (sandwich, uji, soup, fruit)
✗ Avoid heavy meals and gas-producing foods for 24-48 hours (laparoscopic CO₂)
  Gas-producing foods to limit: beans, cabbage, carbonated drinks

DAY 1:
✓ Normal diet tolerated by most patients
✓ High-protein foods to support quick healing: eggs, fish, chicken, beans
✓ 2 litres of water daily
✓ Avoid alcohol for 24 hours (anaesthesia recovery)

1 WEEK:
✓ Full normal diet
✓ No specific long-term dietary modification required for tubal ligation
✓ Resume all normal foods and activity

IF POSTPARTUM (within 48 hours of delivery):
✓ Follow breastfeeding nutrition protocol (same as C-section):
  +500 extra calories daily, high calcium (milk, yoghurt, omena), omega-3

KEY NUTRIENTS:
• Protein: eggs, fish, chicken — 1 week post-op
• Iron (if postpartum): liver, omena, lentils + Vitamin C
• Hydration: 2 litres per day
• Calcium (if breastfeeding): 1200mg/day""",

        "nutrients_research": """KEY NUTRIENTS FOR TUBAL LIGATION RECOVERY

• PROTEIN — standard wound healing support for 1 week
• IRON — especially if postpartum (delivery blood loss)
• HYDRATION — 2 litres daily

RESEARCH EVIDENCE:
- Family planning surgery complication rates in Kenya (Kenya Health Sector Strategic Plan 2023): Postpartum tubal ligation widely performed in Kenya. Complication rates are low in skilled hands.""",
    },

    # ─── ORIF (FRACTURE REPAIR) ──────────────────────────────────────────────
    {
        "name": "Open Fracture Repair (ORIF)",
        "code": "FRACTURE",
        "specialty": "Orthopaedics",

        "overview": """OPEN FRACTURE REPAIR (ORIF) — OVERVIEW AND KENYA CONTEXT

Open Reduction and Internal Fixation (ORIF) is surgery to repair broken bones using plates, screws, intramedullary nails, or external fixators to hold the bone fragments in the correct position while they heal.

IN KENYA — ROAD TRAFFIC ACCIDENTS:
Road traffic accidents (RTAs) are the dominant cause of fractures in Kenya and Sub-Saharan Africa. Kenyatta National Hospital (KNH) has one of East Africa's largest trauma loads. Common fractures:
- Femoral shaft fractures (thigh bone) — treated with intramedullary nailing
- Tibial shaft fractures (shin bone) — nailing or plate fixation
- Forearm fractures — plate fixation
- Hip fractures in elderly (femoral neck) — hip hemiarthroplasty or THR

Kenyan study (Njoroge, Mwangi, Lelei — Annals of African Surgery): Functional outcomes of knee after retrograde vs antegrade intramedullary nailing for femoral shaft fractures in Kenya.

RECOVERY TIMELINE:
- Hospital stay: 5-10 days (major fracture), 1-3 days (forearm, small bones)
- Non-weight-bearing: 6-12 weeks depending on fracture type
- Partial weight-bearing: 6-12 weeks
- Full weight-bearing: 3-6 months
- Bone fully healed: 3-6 months (adult), 4-8 weeks (child)""",

        "procedure": """ORIF — SURGICAL PROCEDURE

INTRAMEDULLARY NAILING (femoral, tibial shaft fractures):
1. Spinal or general anaesthesia
2. Small skin incision at nail entry point
3. Fracture reduced (aligned) on fluoroscopy (X-ray guidance)
4. Guide wire passed down the bone canal
5. Bone canal reamed (widened) gradually
6. Nail of appropriate diameter and length driven into bone
7. Locking screws placed through nail at top and bottom
8. Incisions closed
9. No direct view of fracture site — entirely fluoroscopy-guided

PLATE AND SCREW FIXATION:
1. Incision directly over fracture
2. Fracture exposed and reduced
3. Plate shaped to bone surface
4. Screws inserted to compress fracture and hold plate
5. Wound closed in layers, drain placed

OPEN FRACTURE (bone through skin — contaminated):
Emergency surgery within 6 hours:
1. Thorough irrigation (several litres of saline)
2. Debridement (removal of dead/contaminated tissue)
3. Fracture stabilised with external fixator or nail
4. Wound left open or loosely closed
5. Return to theatre in 48-72 hours for wound check

Duration: 1-4 hours (depends on fracture complexity)""",

        "complications": """ORIF — COMPLICATIONS AND WARNING SIGNS

SERIOUS COMPLICATIONS:
- Infection/osteomyelitis: Bone infection. Most serious complication, especially with open fractures. Signs: fever, increasing pain at fracture site, wound discharge, swelling after initial improvement. Requires prolonged antibiotics and sometimes implant removal.
- Non-union: Bone fails to heal (most common if blood supply poor, infection, smoking, or diabetes). Signs: continued pain at fracture site after 3-4 months, no progression on X-ray. May require re-operation.
- Malunion: Bone heals in wrong position. Shortening, angulation, or rotation. May cause pain and dysfunction. Corrected surgically.
- Implant failure: Plate or nail breaks or screws pull out. Usually from premature weight-bearing or infection. X-ray diagnosis.
- DVT/PE: High risk after lower limb fractures. Calf pain + swelling (DVT). Chest pain + breathlessness (PE — EMERGENCY).
- Compartment syndrome (emergency, mostly in acute phase): Pressure builds inside muscle compartment → cuts off blood supply. Signs: extreme pain out of proportion to injury, pain on passive stretch of fingers/toes, pallor, pulselessness. EMERGENCY — fasciotomy needed within hours.
- Avascular necrosis (AVN): Blood supply to bone head disrupted. Mostly affects femoral head after hip fracture.

HOME MONITORING:
- Fever above 38°C after Day 5
- Increasing pain at fracture site (should decrease)
- Wound redness, discharge, swelling
- Swollen calf or foot (DVT)""",

        "diet_preop": """PRE-OPERATIVE DIET FOR FRACTURE REPAIR

EMERGENCY (most fractures):
- Nothing by mouth immediately — tell staff when you last ate
- IV fluids for trauma stabilisation

ELECTIVE (planned surgery for old fracture or elective fixation):
2 WEEKS BEFORE:
✓ HIGH-PROTEIN (1.5-2.0g/kg/day) — build bone matrix reserves
  Eggs, chicken, fish, omena, milk, yoghurt, beans

✓ CALCIUM 1200mg/day — load bone mineral stores
  Milk, yoghurt, omena, sukuma wiki

✓ VITAMIN D3 800 IU/day — calcium absorption
  Morning sunlight, fatty fish

Standard ERAS fasting day of surgery.""",

        "diet_postop": """POST-OPERATIVE DIET AFTER FRACTURE REPAIR — COMPREHENSIVE BONE HEALING PROTOCOL

BONE HEALING requires specific nutrients in higher amounts than most other surgeries. Feed bone as aggressively as you would feed a wound.

DAYS 0-1:
✓ Clear liquids when haemodynamically stable (stable blood pressure and heart rate)
✓ EMERGENCY fractures may have IV nutrition initially if too unwell to eat

DAYS 2-3:
✓ Soft diet with focus on protein and calcium
✓ Uji with full cream milk (maziwa kamili)
✓ Boiled eggs (mayai ya kuchemsha)
✓ Soft fish: omena stew, tilapia
✓ Begin calcium-rich foods

WEEK 1 AND ONGOING (until bone fully healed — 3-6 months):

✓ HIGH-PROTEIN (1.5-2.0g/kg/day) — CRITICAL for bone matrix (collagen scaffold):
  BEST SOURCES IN KENYA:
  - Omena (3-4 tablespoons per day): HIGH protein AND calcium AND omega-3
  - Eggs (mayai): 2-3 daily
  - Chicken or turkey (kuku): grilled or boiled
  - Beef or goat (nyama): lean cuts 4x per week
  - Lentils (dengu) and beans (maharagwe): high protein
  - Milk (maziwa) and yoghurt (mtindi): every meal

✓ CALCIUM (1200mg/day):
  - Milk (maziwa): 3 glasses per day
  - Yoghurt (mtindi): 2 portions per day
  - OMENA: very high calcium per gram — highest calcium food in Kenya
  - Sukuma wiki (kale): significant calcium
  - Dark greens: spinach (mchicha)

✓ VITAMIN D3 (800-2000 IU/day):
  - Morning sunlight: 30-45 minutes daily
  - Fatty fish: omena, sardines, mackerel
  - Supplement: Vitamin D3 1000 IU/day if sunlight is inadequate

✓ VITAMIN C (500-1000mg/day) — collagen synthesis for bone callus formation:
  - Oranges (machungwa): 2 per day
  - Tomatoes (nyanya): add to every meal
  - Guava (mapera): very high Vitamin C
  - Capsicum/pilipili hoho

✓ ZINC (15-25mg/day) — bone healing enzyme cofactor:
  - Red meat, chicken
  - Pumpkin seeds (mbegu za malenge)
  - Legumes: maharagwe, dengu

✓ OMEGA-3 FATTY ACIDS — anti-inflammatory, supports bone healing:
  - Fish 3x per week: sardines, mackerel, omena (omena best value)
  - Flaxseed (ufuta) if available

WHAT TO AVOID:
✗ ALCOHOL — significantly impairs bone healing. Multiple studies show delayed union.
✗ SMOKING — reduces blood supply to bone, drastically slows healing
✗ EXCESSIVE CAFFEINE (more than 3 cups tea/day) — reduces calcium absorption
✗ Carbonated drinks (soda) — phosphoric acid reduces calcium absorption""",

        "nutrients_research": """KEY NUTRIENTS FOR FRACTURE REPAIR RECOVERY

• PROTEIN (1.5-2.0g/kg/day) — THE MOST CRITICAL NUTRIENT. Bone is 30% collagen protein.
  Without adequate protein, bone callus forms slowly and weakly.
  Sources: omena, eggs, chicken, beef/goat, lentils, milk

• CALCIUM (1200mg/day) — mineral scaffold of bone. Bone is 70% calcium phosphate crystal.
  Sources: OMENA (exceptional calcium per gram), milk (maziwa), yoghurt (mtindi), sukuma wiki

• VITAMIN D3 (800-2000 IU/day) — regulates calcium absorption and bone mineralisation
  Without Vitamin D, calcium is not absorbed from food
  Sources: morning sunlight (most powerful), omena, sardines

• VITAMIN C (500mg/day) — collagen synthesis. Bone callus is made of collagen + calcium crystal.
  Sources: oranges, tomatoes, guava

• ZINC (15-25mg/day) — essential for bone healing enzyme function
  Sources: meat, pumpkin seeds, legumes

RESEARCH EVIDENCE:
- Functional outcomes of knee after femoral shaft nailing in Kenya (Njoroge, Mwangi, Lelei — Annals of African Surgery, 2022): Kenyan data on intramedullary nailing outcomes.
- Pre- and post-surgical nutrition for orthopaedic surgery (PMC/Nutrients, 2021): Protein 2g/kg/day, EAA supplementation, oral nutritional supplements reduce hospitalisation cost by 12.2% in orthopaedic patients.""",
    },

    # ─── CARDIAC SURGERY ─────────────────────────────────────────────────────
    {
        "name": "Cardiac Surgery",
        "code": "CARDIAC",
        "specialty": "Cardiac Surgery",

        "overview": """CARDIAC SURGERY — OVERVIEW AND KENYA CONTEXT

Cardiac surgery encompasses open-heart procedures including valve repair/replacement, coronary artery bypass grafting (CABG), and correction of congenital heart defects.

IN KENYA — A GROWING CAPACITY:
Sub-Saharan Africa faces a severe shortage of cardiac surgery capacity. Kenya's Tenwek Hospital (Bomet County) is a landmark programme that achieved surgical independence during COVID-19 when international surgical missions were suspended. This represents a major achievement for African-led cardiac surgery.

DISEASE PATTERN IN KENYA (different from high-income countries):
- Rheumatic Heart Disease (RHD) dominates: Caused by untreated streptococcal throat infections → rheumatic fever → valve damage. Common in Kenya where access to early antibiotic treatment is limited.
- Congenital heart defects: Unrepaired VSD (hole in heart), ASD, TOF — patients often reach adulthood
- Atherosclerotic coronary disease (CABG): Less common than in high-income countries but increasing with lifestyle change
- Estimated unmet surgical need: millions across sub-Saharan Africa

RECOVERY TIMELINE:
- ICU: 1-3 days (longer for complex cases)
- Hospital: 7-14 days total
- Return to light activity: 6-8 weeks
- Return to driving: 6-8 weeks
- Full recovery: 3-6 months
- Sternal healing: 6-12 weeks (no lifting >5kg during this period)""",

        "procedure": """CARDIAC SURGERY — SURGICAL PROCEDURE

1. General anaesthesia + endotracheal intubation
2. Median sternotomy: chest cut open from top to bottom of sternum (breastbone)
3. Cardiopulmonary bypass (CPB/heart-lung machine) established: cannulas placed in aorta and right atrium, machine takes over heart and lung function
4. Cardiac arrest induced (cardioplegia solution): heart stopped to operate safely
5. SPECIFIC REPAIR:
   - Valve replacement: diseased valve cut out, prosthetic valve (mechanical or biological) sutured in place
   - CABG: saphenous vein (from leg) or internal mammary artery (from chest) used to bypass blocked coronary arteries
   - Congenital defect repair: VSD, ASD closed with patch
6. Heart restarted (defibrillation if needed)
7. Gradual weaning from cardiopulmonary bypass
8. Pacing wires placed (temporary)
9. Chest drains placed
10. Sternal closure with stainless steel wires
11. Soft tissue closure

Duration: 3-8 hours (depends on complexity)

WHAT TO EXPECT:
- Waking up intubated (ventilator) in ICU — extubation usually Day 1
- Chest drains for 24-48 hours
- Temporary pacing wires for 24-72 hours
- Significant chest wall pain and fatigue for 2-4 weeks
- Sternal precautions: no pushing, pulling, lifting >5kg for 6-12 weeks""",

        "complications": """CARDIAC SURGERY — COMPLICATIONS AND WARNING SIGNS

SERIOUS COMPLICATIONS:
- Low cardiac output syndrome: Heart doesn't pump effectively immediately after surgery. Signs: low blood pressure, reduced urine output, poor perfusion. Managed in ICU with medications (inotropes).
- Atrial fibrillation (AF): Irregular heart rhythm. Very common (30-50%) after cardiac surgery. Usually resolves within days-weeks. Requires anticoagulation.
- Stroke: Blood clot or air embolism to brain. Signs: weakness one side, face drooping, speech difficulty. EMERGENCY.
- Bleeding: Can occur from suture lines or around heart. May need re-exploration.
- Sternal wound infection/mediastinitis: Infection of the sternal wound and mediastinum. Very serious. Signs: fever, sternal pain, wound discharge, sternal clicking (unstable sternum). Requires surgical debridement + prolonged antibiotics.
- Acute kidney injury: Kidneys stressed by surgery and bypass. Temporary dialysis may be needed.
- Prolonged ventilation: Some patients cannot breathe independently quickly — ICU stay extended.

HOME MONITORING:
- Sternal wound: redness, swelling, discharge, clicking when moving — see surgeon immediately
- Fever above 38°C after Day 5
- Irregular heartbeat felt (palpitations)
- Leg swelling (DVT) or chest pain (PE)
- Sudden shortness of breath
- Weight gain >2kg in 24 hours (fluid overload — call cardiologist)""",

        "diet_preop": """PRE-OPERATIVE DIET FOR CARDIAC SURGERY

4-6 WEEKS BEFORE (if elective):
✓ CARDIAC DIET:
  - LOW SODIUM (<2g/day): reduces fluid overload pre-op
  - LOW SATURATED FAT: lean meats, fish, plant oils
  - HEART-HEALTHY FOODS: oily fish, nuts, fruits, vegetables, whole grains
  ✗ Avoid: fried foods, butter, ghee (samli), fatty meats, added salt, processed foods

✓ CORRECT MALNUTRITION: Cardiac cachexia (muscle wasting due to heart failure) is common in RHD patients
  - High-protein diet: eggs, fish, chicken, lentils, milk
  - High-calorie if underweight: add groundnut butter to uji, whole milk

✓ CORRECT ANAEMIA: Iron supplementation + iron-rich foods (RHD patients are often anaemic)

✓ VITAMIN K MANAGEMENT (if on warfarin):
  - Do NOT stop Vitamin K foods — maintain CONSISTENT intake
  - Bridging anticoagulation protocol will be managed by cardiologist

STANDARD FASTING:
- Nothing by mouth 6 hours before
- Clear liquids up to 2 hours before""",

        "diet_postop": """POST-OPERATIVE DIET AFTER CARDIAC SURGERY — DAY BY DAY

PHASE 1 — INTUBATED IN ICU:
✓ IV nutrition (total parenteral nutrition/TPN) if prolonged ventilation
✓ Enteral nutrition via nasogastric tube (NGT) if >24 hours ventilated
✗ Nothing by mouth while ventilated

PHASE 2 — EXTUBATED (breathing independently, usually Day 1-2):
✓ Start with clear liquids: water, broth, weak tea, ORS
✓ Progress to soft diet over 24-48 hours
✓ Cardiac-specific principles begin here

ONGOING (full diet from Day 3+):

CARDIAC DIET — LOW SODIUM:
✓ <2g sodium per day (reduces fluid retention and cardiac strain)
✗ DO NOT ADD SALT to food
✗ Avoid salty foods: dried and canned fish (some omena preparations), kachumbari with salt, processed foods
✓ Season with: lemon (ndimu), vinegar, tomatoes, onion, garlic, herbs (manukuu, rosemary), turmeric, ginger

LOW SATURATED FAT:
✓ Lean meats: chicken without skin, fish (samaki), turkey
✓ Cook with: sunflower or olive oil (small amounts only)
✗ Avoid: butter (siagi), ghee (samli), coconut milk (maziwa ya nazi)
✗ Avoid: fatty goat, pork, fried foods

HIGH OMEGA-3 (ANTI-ARRHYTHMIC PROPERTIES):
✓ Oily fish 3x per week: OMENA, sardines, mackerel — directly reduce arrhythmia risk
✓ Flaxseed (ufuta): excellent plant omega-3

POTASSIUM-RICH FOODS (heart muscle function, especially if on diuretics):
✓ Banana (ndizi): eat daily
✓ Avocado (parachichi): high potassium
✓ Sweet potato (viazi vitamu): excellent potassium
✓ Spinach, sukuma wiki
Note: if on potassium-sparing diuretics, monitor potassium with doctor — too much is also dangerous

HIGH PROTEIN (for sternal wound healing — 1.5-2g/kg/day):
✓ Eggs, lean fish (omena, tilapia), chicken, lentils, beans, low-fat milk

WARFARIN PATIENTS (mechanical heart valve, AF):
✓ CONSISTENT VITAMIN K intake — do NOT eliminate Vitamin K foods
✓ Keep sukuma wiki, spinach, broccoli intake CONSISTENT day to day
✗ Do NOT eat large amounts on some days and nothing on others (causes INR fluctuation)
✓ Avoid alcohol (increases bleeding risk + unpredictable INR changes)
✓ Avoid supplements that affect warfarin: Vitamin E high dose, ginkgo

FLUID RESTRICTION (if heart failure present):
✓ 1.5 litres per day maximum (including all liquids: tea, soups, water)
✓ Weigh yourself every morning — report weight gain >2kg in 24 hours to cardiologist""",

        "nutrients_research": """KEY NUTRIENTS FOR CARDIAC SURGERY RECOVERY

• LOW SODIUM (<2g/day) — reduces fluid overload, cardiac strain, blood pressure
  Avoid: table salt, canned foods, dried/salted fish

• OMEGA-3 FATTY ACIDS — anti-arrhythmic, anti-inflammatory
  Evidence: Post-CABG patients on omega-3 have significantly lower AF rates
  Sources: OMENA (excellent value), sardines, mackerel, flaxseed

• POTASSIUM — heart rhythm and muscle function
  Critical if on diuretics (which waste potassium)
  Sources: banana (ndizi), avocado, sweet potato, spinach

• MAGNESIUM — anti-arrhythmic, reduces post-op AF
  Sources: nuts, seeds, dark chocolate, beans, whole grains

• PROTEIN (1.5-2g/kg/day) — sternal wound healing, cardiac muscle repair
• VITAMIN K MANAGEMENT — consistent intake for warfarin patients
• VITAMIN D + CALCIUM — bone strength (sternotomy healing)

RESEARCH EVIDENCE:
- Cardiac Surgery in Sub-Saharan Africa: Anthills of the Savannah (JACC Advances, 2024): Tenwek Hospital Kenya achieved surgical independence during COVID-19. Rheumatic heart disease dominates. Overseas transfers still common. Mentorship models (Cape Town, Maputo, Rwanda Team Heart) key to building local capacity.
- Access to cardiac surgery services in SSA: Quo Vadis? (PubMed, 2020): Critical review of capacity gaps in East Africa; call for self-sufficiency models.
- Access to cardiac surgery in SSA (PubMed, 2015): Foundational paper on scale of the access gap.""",
    },
]


# ─────────────────────────────────────────────────────────────────────────────
# TEXT PROCESSING UTILITIES
# ─────────────────────────────────────────────────────────────────────────────

def clean_text(text: str) -> str:
    """Clean extracted PDF text — remove noise while preserving clinical content."""
    # Collapse excessive whitespace
    text = re.sub(r"\n{3,}", "\n\n", text)
    text = re.sub(r" {2,}", " ", text)
    # Fix hyphenated line breaks (common in PDF extraction)
    text = re.sub(r"(\w)-\n(\w)", r"\1\2", text)
    # Remove page number patterns
    text = re.sub(r"\n\s*\d+\s*\n", "\n", text)
    # Remove common header/footer noise
    text = re.sub(r"Kenya Ministry of Health\s*\n", "", text)
    text = re.sub(r"SalamaRecover.*?\n", "", text)
    return text.strip()


def chunk_text(text: str, chunk_size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP) -> list[str]:
    """
    Split text into overlapping chunks at natural boundaries.
    Tries to split at paragraph boundaries first, then sentence boundaries,
    then word boundaries — never in the middle of a word.
    """
    if not text or len(text) <= chunk_size:
        return [text] if text.strip() else []

    chunks = []
    start = 0

    while start < len(text):
        end = start + chunk_size

        if end >= len(text):
            # Last chunk
            chunk = text[start:].strip()
            if chunk:
                chunks.append(chunk)
            break

        # Try to find a good split point — paragraph, then sentence, then word
        split_pos = None

        # 1. Prefer splitting at double newline (paragraph boundary)
        paragraph_split = text.rfind("\n\n", start, end)
        if paragraph_split > start + chunk_size // 2:
            split_pos = paragraph_split

        # 2. Fall back to sentence boundary (. followed by space)
        if split_pos is None:
            sentence_split = max(
                text.rfind(". ", start, end),
                text.rfind("! ", start, end),
                text.rfind("? ", start, end),
                text.rfind(":\n", start, end),
            )
            if sentence_split > start + chunk_size // 2:
                split_pos = sentence_split + 1  # Include the period

        # 3. Fall back to word boundary (space)
        if split_pos is None:
            word_split = text.rfind(" ", start, end)
            if word_split > start:
                split_pos = word_split

        # 4. Hard split (last resort)
        if split_pos is None:
            split_pos = end

        chunk = text[start:split_pos].strip()
        if chunk:
            chunks.append(chunk)

        # Next chunk starts with overlap
        start = max(split_pos - overlap, start + 1)

    return [c for c in chunks if len(c.strip()) > 50]  # Skip tiny fragments


# ─────────────────────────────────────────────────────────────────────────────
# PDF PROCESSING
# ─────────────────────────────────────────────────────────────────────────────

def process_pdf(filepath: Path, source_name: str, category: str, authority: str) -> list[dict]:
    """
    Extract text from a PDF, chunk it, and return a list of chunk dicts
    ready for embedding and insertion.
    """
    try:
        from pypdf import PdfReader
    except ImportError:
        print("  ERROR: pypdf not installed. Run: pip install pypdf")
        return []

    if not filepath.exists():
        print(f"  SKIP: File not found: {filepath}")
        return []

    print(f"  Loading PDF: {filepath.name}")
    try:
        reader = PdfReader(str(filepath), strict=False)
    except Exception as e:
        print(f"  WARNING: Could not open PDF ({e}). Trying with strict=False...")
        try:
            reader = PdfReader(str(filepath), strict=False)
        except Exception as e2:
            print(f"  ERROR: Cannot open PDF: {e2}")
            return []
    total_pages = len(reader.pages)
    print(f"  Pages: {total_pages}")

    all_chunks = []
    page_text_buffer = ""
    buffer_start_page = 1

    for page_num, page in enumerate(reader.pages, start=1):
        try:
            page_text = page.extract_text() or ""
            page_text = clean_text(page_text)

            if not page_text.strip():
                continue

            page_text_buffer += f"\n\n{page_text}"

            # Process buffer every 3 pages (groups context) or at end
            if page_num % 3 == 0 or page_num == total_pages:
                chunks = chunk_text(page_text_buffer)
                for chunk in chunks:
                    all_chunks.append({
                        "content": chunk,
                        "source": source_name,
                        "page": buffer_start_page,
                        "metadata": {
                            "category": category,
                            "authority": authority,
                            "filename": filepath.name,
                            "page_range": f"{buffer_start_page}-{page_num}",
                        },
                    })
                page_text_buffer = ""
                buffer_start_page = page_num + 1

        except Exception as e:
            print(f"  WARNING: Error extracting page {page_num}: {e}")
            continue

    # Process any remaining buffer
    if page_text_buffer.strip():
        chunks = chunk_text(page_text_buffer)
        for chunk in chunks:
            all_chunks.append({
                "content": chunk,
                "source": source_name,
                "page": buffer_start_page,
                "metadata": {
                    "category": category,
                    "authority": authority,
                    "filename": filepath.name,
                },
            })

    print(f"  Extracted {len(all_chunks)} chunks from {total_pages} pages")
    return all_chunks


# ─────────────────────────────────────────────────────────────────────────────
# SURGERY REFERENCE DATA PROCESSING
# ─────────────────────────────────────────────────────────────────────────────

def process_surgery_data() -> list[dict]:
    """
    Convert the surgery reference data into richly-formatted knowledge base chunks.
    Each surgery produces 6 chunks: overview, procedure, complications,
    pre-op diet, post-op diet, and nutrients + research.
    """
    all_chunks = []
    source_name = "SalamaRecover Surgery Reference — Clinical Protocols for Kenya (2024-2025)"

    CHUNK_TYPES = [
        ("overview",        "Overview & Kenya Context"),
        ("procedure",       "Procedure & What to Expect"),
        ("complications",   "Complications & Warning Signs"),
        ("diet_preop",      "Pre-Operative Diet"),
        ("diet_postop",     "Post-Operative Diet — Day by Day"),
        ("nutrients_research", "Key Nutrients & Research Evidence"),
    ]

    for surgery in SURGERY_DATA:
        for field, label in CHUNK_TYPES:
            content = surgery.get(field, "")
            if not content:
                continue

            # Prepend surgery name and chunk type for retrieval clarity
            full_content = (
                f"SURGERY: {surgery['name']} ({surgery['code']}) | {surgery['specialty']}\n"
                f"TOPIC: {label}\n\n"
                f"{content.strip()}"
            )

            all_chunks.append({
                "content": full_content,
                "source": source_name,
                "page": 0,  # No page number for structured data
                "metadata": {
                    "category": "surgery_reference",
                    "surgery_name": surgery["name"],
                    "surgery_code": surgery["code"],
                    "specialty": surgery["specialty"],
                    "chunk_type": field,
                    "authority": "SalamaRecover Clinical Review 2024-2025",
                },
            })

    print(f"  Generated {len(all_chunks)} surgery reference chunks "
          f"({len(SURGERY_DATA)} surgeries × 6 chunk types)")
    return all_chunks


# ─────────────────────────────────────────────────────────────────────────────
# EMBEDDING
# ─────────────────────────────────────────────────────────────────────────────

def embed_batch(texts: list[str], client) -> list[list[float] | None]:
    """
    Embed a batch of texts in a single API call.
    Returns a list of 768-dimensional vectors (None for any that failed).
    One API call for up to EMBED_BATCH_SIZE texts — dramatically reduces quota usage.

    Retries on 429 (rate limit) by reading retryDelay from the error response.
    """
    if not texts:
        return []

    for attempt in range(MAX_RETRIES + 1):
        try:
            result = client.models.embed_content(
                model=EMBEDDING_MODEL,
                contents=texts,
                config=genai_types.EmbedContentConfig(
                    task_type="RETRIEVAL_DOCUMENT",
                    output_dimensionality=EMBEDDING_DIMENSIONS,
                ),
            )
            return [list(emb.values) for emb in result.embeddings]

        except Exception as e:
            err_str = str(e)

            # On 429, extract retryDelay and wait
            if "429" in err_str or "RESOURCE_EXHAUSTED" in err_str:
                # Try to pull retryDelay seconds from the error message
                delay_match = re.search(r"retryDelay.*?(\d+)s", err_str)
                wait = int(delay_match.group(1)) + 5 if delay_match else 65

                if attempt < MAX_RETRIES:
                    print(f"    RATE LIMIT hit — waiting {wait}s then retrying "
                          f"(attempt {attempt + 1}/{MAX_RETRIES})...")
                    time.sleep(wait)
                    continue
                else:
                    print(f"    QUOTA EXHAUSTED after {MAX_RETRIES} retries. "
                          f"Daily limit reached — see note below.")
                    return [None] * len(texts)
            else:
                print(f"    EMBEDDING ERROR: {e}")
                return [None] * len(texts)

    return [None] * len(texts)


# ─────────────────────────────────────────────────────────────────────────────
# SUPABASE OPERATIONS
# ─────────────────────────────────────────────────────────────────────────────

def source_already_exists(db, source_name: str) -> bool:
    """
    Check if chunks from this source already exist in the knowledge base.
    Used for idempotency — skip sources already processed.
    """
    try:
        result = (
            db.table("knowledge_base")
            .select("id")
            .eq("source", source_name)
            .limit(1)
            .execute()
        )
        return len(result.data) > 0
    except Exception as e:
        print(f"  WARNING: Could not check source existence: {e}")
        return False


def get_chunk_count(db) -> int:
    """Return total number of chunks in the knowledge base."""
    try:
        result = db.table("knowledge_base").select("id", count="exact").execute()
        return result.count or 0
    except Exception:
        return 0


def store_chunks(db, chunks: list[dict], source_name: str, ai_client) -> tuple[int, int]:
    """
    Embed and store chunks into Supabase using BATCH embedding.
    Embeds EMBED_BATCH_SIZE chunks per API call — 10x fewer quota requests.
    Returns (stored_count, error_count).
    """
    # Filter out empty chunks first
    valid_chunks = [c for c in chunks if c.get("content", "").strip()]
    total = len(valid_chunks)
    stored = 0
    errors = 0
    start_time = time.time()
    quota_exhausted = False

    # Process in batches of EMBED_BATCH_SIZE
    for batch_start in range(0, total, EMBED_BATCH_SIZE):
        if quota_exhausted:
            break

        batch = valid_chunks[batch_start: batch_start + EMBED_BATCH_SIZE]
        batch_texts = [c["content"] for c in batch]

        # One API call for the whole batch
        embeddings = embed_batch(batch_texts, ai_client)

        # Check if quota was exhausted (all None after retries)
        if all(e is None for e in embeddings):
            quota_exhausted = True
            errors += len(batch)
            print(f"\n    DAILY QUOTA EXHAUSTED at chunk {batch_start + 1}/{total}.")
            print("    Chunks embedded so far this run will be saved.")
            print("    OPTIONS:")
            print("    1. Wait 24 hours and run again (free tier resets daily)")
            print("    2. Enable billing at console.cloud.google.com")
            print("       (Cost is ~$0.000004 per 1K tokens = nearly free)")
            print("    3. Run again tomorrow — script is idempotent,")
            print("       already-embedded sources will be skipped.\n")
            break

        # Insert each successfully embedded chunk
        for chunk, embedding in zip(batch, embeddings):
            if embedding is None:
                errors += 1
                continue
            try:
                db.table("knowledge_base").insert({
                    "content": chunk["content"],
                    "source": chunk["source"],
                    "page": chunk.get("page", 0),
                    "metadata": chunk.get("metadata", {}),
                    "embedding": embedding,
                }).execute()
                stored += 1
            except Exception as e:
                errors += 1
                if errors <= 3:
                    print(f"    DB ERROR: {e}")

        # Progress report every 5 batches (50 chunks)
        batch_num = batch_start // EMBED_BATCH_SIZE + 1
        total_batches = (total + EMBED_BATCH_SIZE - 1) // EMBED_BATCH_SIZE
        if batch_num % 5 == 0 or batch_num == total_batches:
            elapsed = time.time() - start_time
            rate = stored / max(elapsed, 1)
            remaining = total - (batch_start + len(batch))
            eta_sec = int(remaining / rate) if rate > 0 else 0
            print(f"    Batch {batch_num}/{total_batches} | "
                  f"Stored: {stored}/{total} | "
                  f"Errors: {errors} | "
                  f"ETA: {eta_sec // 60}m {eta_sec % 60}s")

        # Rate limit between batch calls (5 RPM free tier = max 1 call/12s)
        if batch_start + EMBED_BATCH_SIZE < total:
            time.sleep(RATE_LIMIT_SLEEP)

    elapsed = time.time() - start_time
    print(f"    Done: {stored}/{total} stored, {errors} errors, {elapsed:.0f}s")
    return stored, errors


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Build the SalamaRecover RAG Knowledge Base"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Force re-embed all sources, even if they already exist in the DB",
    )
    parser.add_argument(
        "--source",
        type=str,
        default=None,
        help="Process only a specific source (e.g. 'surgery' or filename substring)",
    )
    parser.add_argument(
        "--pdfs-only",
        action="store_true",
        help="Process only PDFs, skip surgery reference data",
    )
    parser.add_argument(
        "--surgery-only",
        action="store_true",
        help="Process only surgery reference data, skip PDFs",
    )
    parser.add_argument(
        "--skip-test",
        action="store_true",
        help="Skip the startup embedding test (use when daily quota is hit but you want to check DB status)",
    )
    args = parser.parse_args()

    print("\n" + "=" * 70)
    print("  SALAMARECOVER — RAG KNOWLEDGE BASE BUILDER")
    print("=" * 70)

    # ── Validate environment variables ──────────────────────────────────────
    gemini_key = os.getenv("GEMINI_API_KEY")
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_KEY")

    missing = []
    if not gemini_key:
        missing.append("GEMINI_API_KEY")
    if not supabase_url:
        missing.append("SUPABASE_URL")
    if not supabase_key:
        missing.append("SUPABASE_SERVICE_KEY")

    if missing:
        print(f"\n  ERROR: Missing environment variables: {', '.join(missing)}")
        print(f"  Add them to: {env_path}")
        print(f"\n  Example .env entries:")
        for var in missing:
            print(f"    {var}=your_value_here")
        sys.exit(1)

    # ── Initialize services ──────────────────────────────────────────────────
    print("\n  Initializing services...")
    ai_client = genai.Client(api_key=gemini_key)
    db = create_client(supabase_url, supabase_key)

    # Test embedding (skip if --skip-test or daily quota is already known to be exhausted)
    if args.skip_test:
        print("  Skipping embedding test (--skip-test). Will attempt embedding during processing.")
    else:
        print("  Testing embedding model...")
        test_results = embed_batch(
            ["post-surgical recovery diet in Kenya with ugali and omena"], ai_client
        )
        test = test_results[0] if test_results else None
        if test is None:
            print()
            print("  DAILY QUOTA EXHAUSTED — cannot embed right now.")
            print("  The free tier allows 1,000 embedding requests per day.")
            print()
            print("  OPTIONS:")
            print("  1. Wait until tomorrow — quota resets at midnight Pacific Time")
            print("  2. Enable billing at console.cloud.google.com/billing")
            print("     (Cost: ~$0.000004 per 1K tokens — essentially free for this project)")
            print("  3. Run with --skip-test to check current DB status without consuming quota")
            print()
            # Show current DB state so the user knows what is already embedded
            db_count = get_chunk_count(db)
            print(f"  Current knowledge base: {db_count} chunks already in Supabase")
            sys.exit(0)  # Exit 0 — not a code error, just a quota issue
        print(f"  Embedding model OK (dimension: {len(test)})")

    # Test database
    print("  Testing database connection...")
    initial_count = get_chunk_count(db)
    print(f"  Database OK (current chunks: {initial_count})")

    if args.force:
        print("\n  --force flag set: ALL sources will be re-embedded")
    print()

    # ── Track overall stats ──────────────────────────────────────────────────
    total_stored = 0
    total_errors = 0
    skipped_sources = []
    processed_sources = []

    # ── PART 1: Surgery Reference Data ──────────────────────────────────────
    if not args.pdfs_only:
        surgery_source = "SalamaRecover Surgery Reference — Clinical Protocols for Kenya (2024-2025)"

        # Apply --source filter
        if args.source and "surgery" not in args.source.lower():
            print("  SKIP: Surgery reference data (filtered out by --source)")
        else:
            print("-" * 70)
            print("  PART 1: Surgery Reference Data")
            print(f"  15 surgeries × 6 chunks each = 90 clinical protocol chunks")
            print("-" * 70)

            if not args.force and source_already_exists(db, surgery_source):
                print(f"  SKIP: Surgery reference already in knowledge base")
                print("  Use --force to re-embed")
                skipped_sources.append("Surgery Reference")
            else:
                chunks = process_surgery_data()
                stored, errors = store_chunks(db, chunks, surgery_source, ai_client)
                total_stored += stored
                total_errors += errors
                processed_sources.append(f"Surgery Reference ({stored} chunks)")

    # ── PART 2: Clinical PDFs ────────────────────────────────────────────────
    if not args.surgery_only:
        print()
        print("-" * 70)
        print("  PART 2: Clinical PDFs")
        print(f"  Directory: {KB_DATA_DIR}")
        print("-" * 70)

        # Sort by priority
        pdf_configs = sorted(PDF_SOURCES, key=lambda x: x["priority"])

        for pdf_config in pdf_configs:
            filepath = KB_DATA_DIR / pdf_config["filename"]
            source_name = pdf_config["source"]

            # Apply --source filter
            if args.source and args.source.lower() not in pdf_config["filename"].lower():
                continue

            print(f"\n  [{pdf_config['priority']}] {pdf_config['source'][:60]}")

            if not filepath.exists():
                print(f"  SKIP: File not found — {filepath.name}")
                continue

            if not args.force and source_already_exists(db, source_name):
                print(f"  SKIP: Already in knowledge base. Use --force to re-embed.")
                skipped_sources.append(pdf_config["filename"])
                continue

            # Process PDF
            chunks = process_pdf(
                filepath=filepath,
                source_name=source_name,
                category=pdf_config["category"],
                authority=pdf_config["authority"],
            )

            if not chunks:
                print(f"  WARNING: No chunks extracted from {filepath.name}")
                continue

            # Embed and store
            stored, errors = store_chunks(db, chunks, source_name, ai_client)
            total_stored += stored
            total_errors += errors
            processed_sources.append(f"{filepath.name[:40]} ({stored} chunks)")

    # ── Final Report ─────────────────────────────────────────────────────────
    final_count = get_chunk_count(db)

    print()
    print("=" * 70)
    print("  KNOWLEDGE BASE BUILD COMPLETE")
    print("=" * 70)
    print(f"\n  Sources processed:  {len(processed_sources)}")
    for s in processed_sources:
        print(f"    ✓ {s}")

    if skipped_sources:
        print(f"\n  Sources skipped (already embedded):  {len(skipped_sources)}")
        for s in skipped_sources:
            print(f"    — {s}")

    print(f"\n  Chunks stored this run: {total_stored}")
    print(f"  Errors this run:        {total_errors}")
    print(f"  Total chunks in DB:     {final_count}")

    if total_errors > 0:
        print(f"\n  WARNING: {total_errors} chunks failed to embed.")
        print("  Run again to retry failed chunks.")
    else:
        print("\n  All chunks embedded successfully!")

    print()
    print("  The AI chat is now grounded in:")
    print("  • Surgery-specific recovery protocols with Kenyan food names")
    print("  • Kenya MOH clinical nutrition guidelines")
    print("  • Food composition data for Kenyan foods")
    print("  • Obstetrics & perinatal care guidelines")
    print("  • Evidence from Lancet, JAMA, Annals of African Surgery")
    print()
    print("  Run the API server and test the chat endpoint:")
    print("  POST /api/chat/ with a patient context and a question")
    print("=" * 70)


if __name__ == "__main__":
    main()
