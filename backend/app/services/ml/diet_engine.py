"""
Diet Engine — surgery-specific meal plans aligned with Kenya MOH Nutrition Manual
and evidence-based surgical recovery protocols (ERAS Society, WHO guidelines).

This is a rules-based engine (not ML) because diet progression is a well-defined
clinical protocol. Uses Kenya-local foods (ugali, sukuma wiki, omena, uji, etc.)
referenced to the Kenya National Clinical Nutrition and Dietetics Reference Manual
(MOH, 2010) and ERAS Society surgical nutrition guidelines.

SUPPORTED SURGERY TYPES (15):
═══════════════════════════════
Obstetrics:     Caesarean Section
General:        Appendectomy, Hernia Repair, Cholecystectomy, Laparotomy
Gynaecology:    Hysterectomy, Tubal Ligation, Myomectomy
Orthopaedics:   Knee Replacement, Hip Replacement, Open Fracture Repair
Urology:        Prostatectomy
Endocrine:      Thyroidectomy
Oncology:       Mastectomy
Cardiac:        Cardiac Surgery

NAME NORMALISATION:
════════════════════
surgery_type stored in DB is plain text. This engine normalises variations
(e.g. "Inguinal Hernia Repair" → "Hernia Repair") so all 15 types resolve
to a canonical key that has a diet plan.

KEY NUTRIENTS:
═══════════════
Each surgery type carries a key_nutrients string listing priority micronutrients
that should be emphasised in every phase. This is exposed in the API response
so the Flutter diet screen can highlight them.
"""

from app.schemas.recovery import DietResponse, FoodItem

# ─────────────────────────────────────────────────────────────────────────────
# SURGERY NAME NORMALISATION
# Maps full/variant names the Flutter profile screen may send → canonical keys
# ─────────────────────────────────────────────────────────────────────────────
SURGERY_NAME_ALIASES: dict[str, str] = {
    # Caesarean Section
    "C-Section": "Caesarean Section",
    "C Section": "Caesarean Section",
    "Cesarean Section": "Caesarean Section",
    "Caesarean": "Caesarean Section",

    # Hernia Repair
    "Inguinal Hernia Repair": "Hernia Repair",
    "Inguinal Hernia": "Hernia Repair",
    "Hernia": "Hernia Repair",

    # Appendectomy
    "Appendix Removal": "Appendectomy",
    "Appy": "Appendectomy",

    # Laparotomy
    "Laparotomy (Exploratory)": "Laparotomy",
    "Exploratory Laparotomy": "Laparotomy",

    # Open Fracture Repair
    "Open Fracture Repair (ORIF)": "Open Fracture Repair",
    "ORIF": "Open Fracture Repair",
    "Fracture Repair": "Open Fracture Repair",
    "Fracture Surgery": "Open Fracture Repair",

    # Knee Replacement
    "Knee Replacement (TKR)": "Knee Replacement",
    "TKR": "Knee Replacement",
    "Total Knee Replacement": "Knee Replacement",

    # Hip Replacement
    "Hip Replacement (THR)": "Hip Replacement",
    "THR": "Hip Replacement",
    "Total Hip Replacement": "Hip Replacement",

    # Prostatectomy
    "Radical Prostatectomy": "Prostatectomy",
    "Simple Prostatectomy": "Prostatectomy",

    # Thyroidectomy
    "Total Thyroidectomy": "Thyroidectomy",
    "Partial Thyroidectomy": "Thyroidectomy",
    "Thyroid Surgery": "Thyroidectomy",

    # Mastectomy
    "Modified Radical Mastectomy": "Mastectomy",
    "MRM": "Mastectomy",
    "Breast Removal": "Mastectomy",

    # Cardiac Surgery
    "Open Heart Surgery": "Cardiac Surgery",
    "CABG": "Cardiac Surgery",
    "Valve Replacement": "Cardiac Surgery",
    "Heart Surgery": "Cardiac Surgery",
}

# ─────────────────────────────────────────────────────────────────────────────
# KEY NUTRIENTS PER SURGERY TYPE
# Exposed in API response so the Flutter Diet screen can highlight priorities
# ─────────────────────────────────────────────────────────────────────────────
SURGERY_KEY_NUTRIENTS: dict[str, str] = {
    "Caesarean Section":    "Iron, Vitamin C, Calcium, Zinc, Omega-3, Protein (≥1.5 g/kg/day)",
    "Appendectomy":         "Protein, Zinc, Vitamin C, Probiotics (post-antibiotic)",
    "Hernia Repair":        "Fibre (25–35 g/day), Protein, Water, Zinc",
    "Cholecystectomy":      "Low fat, Fibre, Fat-soluble Vitamins (A, D, E, K), Protein",
    "Laparotomy":           "Protein, Glutamine, Zinc, Vitamin A, Electrolytes",
    "Hysterectomy":         "Iron, Calcium, Vitamin D, Omega-3, Protein",
    "Tubal Ligation":       "Protein, Iron (if postpartum), Hydration",
    "Open Fracture Repair": "Calcium, Vitamin D3, Vitamin C, Zinc, Protein (2 g/kg/day)",
    "Prostatectomy":        "Lycopene, Selenium, Zinc, Omega-3, Fibre, Vitamin E",
    "Thyroidectomy":        "Calcium, Vitamin D3, Iodine (if cancer-free), Selenium",
    "Knee Replacement":     "Protein (2 g/kg/day), Calcium, Vitamin D, Omega-3, Vitamin C",
    "Hip Replacement":      "Protein, Calcium, Vitamin D, Iron (if sickle cell), Hydration",
    "Mastectomy":           "Protein, Omega-3, Antioxidants (Vit C, E), Calcium, Vitamin D",
    "Myomectomy":           "Iron, Vitamin C (with iron), Calcium, Vitamin D, Protein",
    "Cardiac Surgery":      "Low sodium, Omega-3, Potassium, Magnesium, Protein, Vitamin K",
}

# ─────────────────────────────────────────────────────────────────────────────
# SURGICAL DIET PROGRESSION
# Format: { "Surgery Type": { (day_start, day_end): { phase data } } }
# Source: Kenya National Clinical Nutrition & Dietetics Reference Manual (MOH 2010)
#         + ERAS Society Guidelines + WHO Surgical Safety Guidelines
# ─────────────────────────────────────────────────────────────────────────────
SURGICAL_DIET_PROGRESSION: dict[str, dict[tuple[int, int], dict]] = {

    # ══════════════════════════════════════════════════════════════════════════
    # 1. CAESAREAN SECTION
    # Protocol: ERAS-based (AJOG 2025) + Kenya MOH Manual
    # ══════════════════════════════════════════════════════════════════════════
    "Caesarean Section": {
        (1, 2): {
            "phase": "Clear Liquid Diet",
            "kcal": 500,
            "foods": [
                FoodItem(icon="🫖", name="Black tea (no milk)", benefit="Hydration", source="MOH p.66"),
                FoodItem(icon="🥣", name="Clear broth (supu)", benefit="Electrolytes", source="MOH p.66"),
                FoodItem(icon="🧃", name="Strained juice", benefit="Vitamins", source="MOH p.66"),
                FoodItem(icon="💧", name="Water / ORS", benefit="Hydration + electrolytes", source="MOH p.66"),
            ],
            "avoid": ["Milk", "Solid food", "Carbonated drinks"],
            "source": "Kenya Nutrition Manual p.66 · ERAS Society ERAC 2025",
        },
        (3, 4): {
            "phase": "Full Liquid Diet",
            "kcal": 1500,
            "foods": [
                FoodItem(icon="🥣", name="Uji wa unga", benefit="Energy + easy digestion", source="MOH p.67"),
                FoodItem(icon="🥛", name="Maziwa (milk)", benefit="Calcium + protein", source="MOH p.67"),
                FoodItem(icon="🫙", name="Mtindi (yoghurt)", benefit="Probiotics + calcium", source="MOH p.67"),
                FoodItem(icon="🍲", name="Supu (soup)", benefit="Nutrients + hydration", source="MOH p.67"),
            ],
            "avoid": ["Solid food", "Spicy foods", "Raw vegetables"],
            "source": "Kenya Nutrition Manual p.67",
        },
        (5, 7): {
            "phase": "Soft Diet",
            "kcal": 2000,
            "foods": [
                FoodItem(icon="🫓", name="Ugali laini", benefit="Slow-release energy", source="MOH p.69"),
                FoodItem(icon="🥚", name="Mayai (eggs)", benefit="Complete protein", source="MOH p.69"),
                FoodItem(icon="🍌", name="Ndizi (banana)", benefit="Potassium + energy", source="MOH p.69"),
                FoodItem(icon="🥭", name="Papai (pawpaw)", benefit="Vitamin C for wound healing", source="MOH p.69"),
            ],
            "avoid": ["Hard foods", "Raw vegetables", "Spicy food"],
            "source": "Kenya Nutrition Manual p.69",
        },
        (8, 999): {
            "phase": "High Protein High Calorie Diet",
            "kcal": 2500,
            "foods": [
                FoodItem(icon="🫓", name="Ugali", benefit="Energy base", source="MOH p.75"),
                FoodItem(icon="🫘", name="Maharagwe (beans)", benefit="Plant protein + fibre", source="MOH p.75"),
                FoodItem(icon="🐟", name="Samaki (fish)", benefit="Omega-3 + protein", source="MOH p.75"),
                FoodItem(icon="🍗", name="Kuku (chicken)", benefit="Lean protein", source="MOH p.75"),
                FoodItem(icon="🥬", name="Sukuma wiki", benefit="Iron + Vitamin K", source="MOH p.75"),
                FoodItem(icon="🥑", name="Avokado", benefit="Healthy fats + Vitamin E", source="MOH p.75"),
            ],
            "avoid": ["Excessive sugar", "Processed foods", "Alcohol (breastfeeding)"],
            "source": "Kenya Nutrition Manual p.75 — 35-40 kcal/kg, ≥1.5 g protein/kg/day",
        },
    },

    # ══════════════════════════════════════════════════════════════════════════
    # 2. APPENDECTOMY
    # Protocol: Low-fibre first → high-fibre stepwise (MOH p.69-71)
    # ══════════════════════════════════════════════════════════════════════════
    "Appendectomy": {
        (1, 2): {
            "phase": "Clear Liquid Diet",
            "kcal": 500,
            "foods": [
                FoodItem(icon="🫖", name="Black tea", benefit="Hydration", source="MOH p.66"),
                FoodItem(icon="🥣", name="Clear broth", benefit="Electrolytes", source="MOH p.66"),
                FoodItem(icon="💧", name="Water / ORS", benefit="Hydration", source="MOH p.66"),
            ],
            "avoid": ["Milk", "Solid food", "High fibre foods", "Beans"],
            "source": "Kenya Nutrition Manual p.66",
        },
        (3, 5): {
            "phase": "Low Fibre Soft Diet",
            "kcal": 1500,
            "foods": [
                FoodItem(icon="🥣", name="Uji", benefit="Easy digestion", source="MOH p.69"),
                FoodItem(icon="🥚", name="Boiled eggs", benefit="Protein", source="MOH p.69"),
                FoodItem(icon="🍌", name="Ripe banana", benefit="Gentle on stomach", source="MOH p.69"),
                FoodItem(icon="🍚", name="White rice (wali)", benefit="Low-fibre energy", source="MOH p.69"),
            ],
            "avoid": ["High fibre foods", "Raw vegetables", "Beans", "Carbonated drinks"],
            "source": "Kenya Nutrition Manual p.69",
        },
        (6, 999): {
            "phase": "High Fibre Normal Diet",
            "kcal": 2200,
            "foods": [
                FoodItem(icon="🫘", name="Githeri (beans + maize)", benefit="Fibre + protein", source="MOH p.71"),
                FoodItem(icon="🥬", name="Sukuma wiki", benefit="Fibre + iron", source="MOH p.71"),
                FoodItem(icon="🫓", name="Ugali", benefit="Energy", source="MOH p.71"),
                FoodItem(icon="🍠", name="Viazi vitamu (sweet potatoes)", benefit="Fibre + Vitamin A", source="MOH p.71"),
                FoodItem(icon="🥭", name="Papai (pawpaw)", benefit="Digestive enzymes + Vitamin C", source="MOH p.71"),
            ],
            "avoid": ["Excessive spicy food"],
            "source": "Kenya Nutrition Manual p.71",
        },
    },

    # ══════════════════════════════════════════════════════════════════════════
    # 3. HERNIA REPAIR (Inguinal Hernia Repair)
    # Protocol: High-fibre anti-straining — prevent constipation on wound
    # ══════════════════════════════════════════════════════════════════════════
    "Hernia Repair": {
        (1, 3): {
            "phase": "Soft Low Fibre Diet",
            "kcal": 1500,
            "foods": [
                FoodItem(icon="🥣", name="Uji", benefit="Easy digestion", source="MOH p.69"),
                FoodItem(icon="🥚", name="Mayai ya kuchemsha", benefit="Soft protein", source="MOH p.69"),
                FoodItem(icon="🍌", name="Ndizi iliyopondwa", benefit="Gentle energy", source="MOH p.69"),
                FoodItem(icon="🍚", name="White rice", benefit="Low-fibre, easy on gut", source="MOH p.69"),
            ],
            "avoid": ["High fibre foods", "Beans", "Raw vegetables", "Gas-forming foods"],
            "source": "Kenya Nutrition Manual p.69",
        },
        (4, 999): {
            "phase": "High Fibre Diet",
            "kcal": 2200,
            "foods": [
                FoodItem(icon="🫘", name="Maharagwe (beans)", benefit="Fibre prevents straining on wound", source="MOH p.71"),
                FoodItem(icon="🥬", name="Sukuma wiki", benefit="Fibre + vitamins", source="MOH p.71"),
                FoodItem(icon="🍠", name="Viazi vitamu", benefit="Gentle soluble fibre", source="MOH p.71"),
                FoodItem(icon="🥭", name="Papai", benefit="Digestive enzymes", source="MOH p.71"),
                FoodItem(icon="🐟", name="Samaki (fish)", benefit="Protein for mesh integration", source="MOH p.75"),
            ],
            "avoid": ["Straining / constipating foods", "Excessive dairy", "Alcohol", "Carbonated drinks"],
            "source": "Kenya Nutrition Manual p.71 — high fibre (25-35 g/day) to prevent straining",
        },
    },

    # ══════════════════════════════════════════════════════════════════════════
    # 4. CHOLECYSTECTOMY (Gallbladder Removal)
    # Protocol: Fat-restricted progressive — no gallbladder bile pooling
    # ══════════════════════════════════════════════════════════════════════════
    "Cholecystectomy": {
        (1, 3): {
            "phase": "Fat-Free Clear/Liquid Diet",
            "kcal": 800,
            "foods": [
                FoodItem(icon="💧", name="Water / ORS", benefit="Hydration", source="MOH p.74"),
                FoodItem(icon="🫖", name="Black tea (no milk)", benefit="Zero fat", source="MOH p.74"),
                FoodItem(icon="🧃", name="Strained fruit juice", benefit="Vitamins, zero fat", source="MOH p.74"),
                FoodItem(icon="🥣", name="Clear broth (no fat)", benefit="Electrolytes", source="MOH p.74"),
            ],
            "avoid": ["All fat", "Milk", "Fried foods", "Butter", "Avocado"],
            "source": "Kenya Nutrition Manual p.74 — zero fat day 1-3",
        },
        (4, 14): {
            "phase": "Very Low Fat Soft Diet",
            "kcal": 1600,
            "foods": [
                FoodItem(icon="🥣", name="Uji (no butter/fat)", benefit="Low fat energy", source="MOH p.74"),
                FoodItem(icon="🥚", name="Boiled egg white only", benefit="Zero-fat protein", source="MOH p.74"),
                FoodItem(icon="🐟", name="Steamed fish (samaki)", benefit="Low fat protein", source="MOH p.74"),
                FoodItem(icon="🍌", name="Matunda (fruits)", benefit="Vitamins, zero fat", source="MOH p.74"),
                FoodItem(icon="🥬", name="Mboga za kuchemsha", benefit="Fibre, no fat", source="MOH p.74"),
            ],
            "avoid": ["Fried foods", "Butter", "Full cream milk", "Avocado", "Fatty meat", "Coconut"],
            "source": "Kenya Nutrition Manual p.74 — max 10 g fat/day weeks 1-2",
        },
        (15, 999): {
            "phase": "Low Fat Normal Diet",
            "kcal": 2000,
            "foods": [
                FoodItem(icon="🥣", name="Uji (low-fat)", benefit="Energy", source="MOH p.74"),
                FoodItem(icon="🥚", name="Boiled eggs", benefit="Lean protein", source="MOH p.74"),
                FoodItem(icon="🐟", name="Steamed / boiled fish", benefit="Low fat omega-3", source="MOH p.74"),
                FoodItem(icon="🍠", name="Viazi vitamu", benefit="Fibre + Vitamin A", source="MOH p.74"),
                FoodItem(icon="🫘", name="Beans (boiled)", benefit="Fibre + protein", source="MOH p.74"),
                FoodItem(icon="🥬", name="Sukuma wiki", benefit="Fibre + iron", source="MOH p.74"),
            ],
            "avoid": ["Fried foods", "Fatty meats", "Alcohol", "Carbonated drinks", "Spicy foods"],
            "source": "Kenya Nutrition Manual p.74 — max 30 g fat/day. Most patients tolerate full diet by Week 8",
        },
    },

    # ══════════════════════════════════════════════════════════════════════════
    # 5. LAPAROTOMY (Exploratory)
    # Protocol: Modified C-Section (general abdominal) — wait for bowel function
    # ══════════════════════════════════════════════════════════════════════════
    "Laparotomy": {
        (1, 3): {
            "phase": "Clear Liquid Diet (Bowel Rest)",
            "kcal": 500,
            "foods": [
                FoodItem(icon="💧", name="Water / ORS", benefit="Hydration + electrolytes", source="MOH p.66"),
                FoodItem(icon="🫖", name="Black tea (no milk)", benefit="Hydration", source="MOH p.66"),
                FoodItem(icon="🥣", name="Clear broth (supu)", benefit="Electrolytes", source="MOH p.66"),
                FoodItem(icon="🧃", name="Strained juice", benefit="Vitamins", source="MOH p.66"),
            ],
            "avoid": ["All solid food", "Milk", "High fibre", "Carbonated drinks"],
            "source": "Kenya Nutrition Manual p.66 — nil by mouth until bowel sounds return",
        },
        (4, 7): {
            "phase": "Soft High Protein Diet",
            "kcal": 1800,
            "foods": [
                FoodItem(icon="🥣", name="Uji wa unga", benefit="Gentle energy", source="MOH p.69"),
                FoodItem(icon="🥚", name="Mayai ya kuchemsha", benefit="Complete protein", source="MOH p.69"),
                FoodItem(icon="🐟", name="Samaki wa kuchemsha", benefit="Lean protein", source="MOH p.69"),
                FoodItem(icon="🍌", name="Ndizi mbivu", benefit="Potassium + energy", source="MOH p.69"),
                FoodItem(icon="🫙", name="Mtindi (yoghurt)", benefit="Probiotics + protein", source="MOH p.69"),
            ],
            "avoid": ["Raw vegetables", "Hard/tough foods", "Beans", "Carbonated drinks", "Spicy foods"],
            "source": "Kenya Nutrition Manual p.69 — early oral feeding within 24-48 h if bowel functioning",
        },
        (8, 999): {
            "phase": "High Protein High Calorie Diet",
            "kcal": 2500,
            "foods": [
                FoodItem(icon="🫓", name="Ugali", benefit="Energy base", source="MOH p.75"),
                FoodItem(icon="🫘", name="Maharagwe (beans)", benefit="Protein + fibre", source="MOH p.75"),
                FoodItem(icon="🐟", name="Samaki (fish)", benefit="Omega-3 + protein", source="MOH p.75"),
                FoodItem(icon="🍗", name="Kuku (chicken)", benefit="Lean protein", source="MOH p.75"),
                FoodItem(icon="🥬", name="Sukuma wiki", benefit="Iron + Vitamin A", source="MOH p.75"),
                FoodItem(icon="🥚", name="Mayai (eggs)", benefit="Zinc + protein", source="MOH p.75"),
            ],
            "avoid": ["Excessive sugar", "Processed foods", "Alcohol"],
            "source": "Kenya Nutrition Manual p.75 — 1.5 g protein/kg/day for abdominal wound healing",
        },
    },

    # ══════════════════════════════════════════════════════════════════════════
    # 6. HYSTERECTOMY
    # Protocol: Modified C-Section + hormonal considerations (ERAS GYN)
    # ══════════════════════════════════════════════════════════════════════════
    "Hysterectomy": {
        (1, 1): {
            "phase": "Clear Liquid Diet",
            "kcal": 500,
            "foods": [
                FoodItem(icon="💧", name="Water / ORS", benefit="Hydration", source="MOH p.66"),
                FoodItem(icon="🫖", name="Black tea (no milk)", benefit="Hydration", source="MOH p.66"),
                FoodItem(icon="🥣", name="Clear broth", benefit="Electrolytes", source="MOH p.66"),
                FoodItem(icon="🧃", name="Strained juice", benefit="Vitamins", source="MOH p.66"),
            ],
            "avoid": ["Solid food", "Milk", "Spicy foods"],
            "source": "ERAS GYN — clear liquids from 4 hours post-op",
        },
        (2, 5): {
            "phase": "Low-Fat Soft Diet",
            "kcal": 1800,
            "foods": [
                FoodItem(icon="🥣", name="Uji (low-fat)", benefit="Easy digestion", source="MOH p.69"),
                FoodItem(icon="🥚", name="Boiled eggs", benefit="Protein", source="MOH p.69"),
                FoodItem(icon="🐟", name="Steamed fish", benefit="Lean protein + omega-3", source="MOH p.69"),
                FoodItem(icon="🍌", name="Ndizi (banana)", benefit="Potassium + energy", source="MOH p.69"),
                FoodItem(icon="🫙", name="Mtindi (yoghurt)", benefit="Calcium + probiotics", source="MOH p.69"),
            ],
            "avoid": ["Fried foods", "Spicy foods", "Raw vegetables", "Hard-to-digest legumes"],
            "source": "ERAS GYN Nutrition Guidelines — MD Anderson 2023, low-fat first foods",
        },
        (6, 999): {
            "phase": "Anti-Inflammatory High Protein Diet",
            "kcal": 2300,
            "foods": [
                FoodItem(icon="🐟", name="Samaki (fish)", benefit="Omega-3 — anti-inflammatory", source="MOH p.75"),
                FoodItem(icon="🥬", name="Sukuma wiki", benefit="Iron + Vitamin K", source="MOH p.75"),
                FoodItem(icon="🫘", name="Maharagwe (beans)", benefit="Iron + protein", source="MOH p.75"),
                FoodItem(icon="🥛", name="Maziwa / mtindi", benefit="Calcium for bone protection", source="MOH p.75"),
                FoodItem(icon="🐠", name="Omena (small fish)", benefit="High calcium — bone health", source="MOH p.75"),
                FoodItem(icon="🍊", name="Machungwa (orange)", benefit="Vitamin C + iron absorption", source="MOH p.75"),
                FoodItem(icon="🫓", name="Ugali", benefit="Energy", source="MOH p.75"),
            ],
            "avoid": ["Alcohol", "Excessive saturated fat", "Processed foods"],
            "source": "Kenya Nutrition Manual p.75 + ESPEN Clinical Nutrition 2021 — iron if pre-op anaemia; calcium if oophorectomy",
        },
    },

    # ══════════════════════════════════════════════════════════════════════════
    # 7. TUBAL LIGATION
    # Protocol: Minor abdominal — very short recovery (15-30 min procedure)
    # ══════════════════════════════════════════════════════════════════════════
    "Tubal Ligation": {
        (1, 1): {
            "phase": "Clear Liquid Diet",
            "kcal": 500,
            "foods": [
                FoodItem(icon="💧", name="Water / ORS", benefit="Hydration", source="MOH p.66"),
                FoodItem(icon="🫖", name="Black tea", benefit="Hydration", source="MOH p.66"),
                FoodItem(icon="🥣", name="Clear broth", benefit="Electrolytes", source="MOH p.66"),
            ],
            "avoid": ["Solid food initially", "Gas-forming foods (laparoscopic CO₂)", "Carbonated drinks"],
            "source": "Kenya Nutrition Manual p.66 — clear liquids 2-4 h after minor procedure",
        },
        (2, 7): {
            "phase": "Normal Soft Diet + High Protein",
            "kcal": 2000,
            "foods": [
                FoodItem(icon="🥣", name="Uji / porridge", benefit="Easy-to-digest energy", source="MOH p.69"),
                FoodItem(icon="🥚", name="Eggs", benefit="Protein for wound healing", source="MOH p.69"),
                FoodItem(icon="🍌", name="Ndizi (banana)", benefit="Potassium + energy", source="MOH p.69"),
                FoodItem(icon="🐟", name="Samaki (fish)", benefit="Protein + omega-3", source="MOH p.69"),
                FoodItem(icon="🥬", name="Mboga (vegetables)", benefit="Vitamins + fibre", source="MOH p.69"),
            ],
            "avoid": ["Beans/cabbage for 48 h (gas after laparoscopic CO₂)", "Carbonated drinks", "Alcohol"],
            "source": "Kenya Nutrition Manual p.69",
        },
        (8, 999): {
            "phase": "Normal Full Diet + Iron Focus",
            "kcal": 2200,
            "foods": [
                FoodItem(icon="🫓", name="Ugali", benefit="Energy", source="MOH p.71"),
                FoodItem(icon="🫘", name="Maharagwe (beans)", benefit="Plant protein + iron", source="MOH p.71"),
                FoodItem(icon="🐟", name="Samaki", benefit="Omega-3 + protein", source="MOH p.71"),
                FoodItem(icon="🥬", name="Sukuma wiki", benefit="Iron + folate (postpartum)", source="MOH p.71"),
                FoodItem(icon="🥛", name="Maziwa (milk)", benefit="Calcium", source="MOH p.71"),
                FoodItem(icon="🍊", name="Machungwa", benefit="Vitamin C + iron absorption", source="MOH p.71"),
            ],
            "avoid": ["Alcohol", "Excessive caffeine"],
            "source": "Kenya Nutrition Manual p.71 — if postpartum, follow breastfeeding nutrition (+500 kcal/day)",
        },
    },

    # ══════════════════════════════════════════════════════════════════════════
    # 8. OPEN FRACTURE REPAIR (ORIF)
    # Protocol: Bone healing high-calcium/protein (PMC/Nutrients 2021)
    # ══════════════════════════════════════════════════════════════════════════
    "Open Fracture Repair": {
        (1, 2): {
            "phase": "Clear Liquid Diet (Trauma Stabilisation)",
            "kcal": 500,
            "foods": [
                FoodItem(icon="💧", name="Water / ORS", benefit="Fluid resuscitation", source="MOH p.66"),
                FoodItem(icon="🫖", name="Black tea", benefit="Hydration", source="MOH p.66"),
                FoodItem(icon="🥣", name="Clear broth", benefit="Electrolytes", source="MOH p.66"),
                FoodItem(icon="🧃", name="Strained juice", benefit="Vitamin C — collagen synthesis", source="MOH p.66"),
            ],
            "avoid": ["Solid food", "Alcohol (impairs bone healing)", "Carbonated drinks"],
            "source": "Kenya Nutrition Manual p.66 — haemodynamic stabilisation first",
        },
        (3, 7): {
            "phase": "High Protein Calcium Soft Diet",
            "kcal": 2000,
            "foods": [
                FoodItem(icon="🥣", name="Uji with milk", benefit="Calcium + energy", source="MOH p.69"),
                FoodItem(icon="🥚", name="Boiled eggs", benefit="Complete protein + zinc", source="MOH p.69"),
                FoodItem(icon="🐠", name="Omena (small fish with bones)", benefit="Very high calcium — bone matrix", source="MOH p.69"),
                FoodItem(icon="🍌", name="Ndizi (banana)", benefit="Potassium + energy", source="MOH p.69"),
                FoodItem(icon="🫙", name="Mtindi (yoghurt)", benefit="Calcium + probiotics", source="MOH p.69"),
                FoodItem(icon="🥭", name="Papai / machungwa", benefit="Vitamin C — collagen for callus", source="MOH p.69"),
            ],
            "avoid": ["Alcohol (critical — impairs bone healing)", "Excessive caffeine", "Carbonated drinks"],
            "source": "Kenya Nutrition Manual p.69 — Vitamin D3 800-2000 IU/day; Calcium 1200 mg/day",
        },
        (8, 999): {
            "phase": "Bone Healing High Protein Diet",
            "kcal": 2500,
            "foods": [
                FoodItem(icon="🐠", name="Omena (small fish)", benefit="Highest calcium food in Kenya diet", source="MOH p.75"),
                FoodItem(icon="🥛", name="Maziwa (milk)", benefit="Calcium 1200 mg/day target", source="MOH p.75"),
                FoodItem(icon="🫓", name="Ugali", benefit="Energy for bone repair", source="MOH p.75"),
                FoodItem(icon="🍗", name="Kuku (chicken)", benefit="Protein 2 g/kg/day for bone matrix", source="MOH p.75"),
                FoodItem(icon="🐟", name="Samaki (fish)", benefit="Omega-3 anti-inflammatory", source="MOH p.75"),
                FoodItem(icon="🥬", name="Sukuma wiki", benefit="Vitamin K + Vitamin A", source="MOH p.75"),
                FoodItem(icon="🍊", name="Machungwa (orange)", benefit="Vitamin C 500-1000 mg/day", source="MOH p.75"),
            ],
            "avoid": ["Alcohol (stop completely — impairs bone healing)", "Smoking", "Excessive caffeine"],
            "source": "Kenya Nutrition Manual p.75 + PMC/Nutrients 2021 — 2 g protein/kg/day; Zinc 15-25 mg/day",
        },
    },

    # ══════════════════════════════════════════════════════════════════════════
    # 9. PROSTATECTOMY
    # Protocol: Modified C-Section + prostate-specific nutrients
    # ══════════════════════════════════════════════════════════════════════════
    "Prostatectomy": {
        (1, 2): {
            "phase": "Clear Liquid Diet (Catheter Period)",
            "kcal": 500,
            "foods": [
                FoodItem(icon="💧", name="Water (2-3 L/day)", benefit="Flushes urinary system with catheter", source="MOH p.66"),
                FoodItem(icon="🫖", name="Black tea / herbal tea", benefit="Hydration", source="MOH p.66"),
                FoodItem(icon="🥣", name="Clear broth", benefit="Electrolytes", source="MOH p.66"),
                FoodItem(icon="🧃", name="Strained juice", benefit="Vitamins", source="MOH p.66"),
            ],
            "avoid": ["Solid food", "Alcohol (catheter period)", "Carbonated drinks", "Spicy foods"],
            "source": "Kenya Nutrition Manual p.66",
        },
        (3, 7): {
            "phase": "High Fibre Soft Diet (Anti-Straining)",
            "kcal": 2000,
            "foods": [
                FoodItem(icon="🥣", name="Uji", benefit="Easy digestion", source="MOH p.69"),
                FoodItem(icon="🥚", name="Boiled eggs", benefit="Protein + zinc", source="MOH p.69"),
                FoodItem(icon="🍌", name="Ndizi (banana)", benefit="Potassium + gentle fibre", source="MOH p.69"),
                FoodItem(icon="🐟", name="Steamed fish", benefit="Omega-3 — anti-inflammatory", source="MOH p.69"),
                FoodItem(icon="🥭", name="Papai (pawpaw)", benefit="Digestive enzymes — prevent constipation", source="MOH p.69"),
                FoodItem(icon="🍠", name="Viazi vitamu", benefit="Fibre + Vitamin A", source="MOH p.69"),
            ],
            "avoid": ["Spicy foods", "Raw vegetables", "Alcohol", "Red/processed meat"],
            "source": "Kenya Nutrition Manual p.69 — high fibre critical: bowel movements must not strain anastomosis",
        },
        (8, 999): {
            "phase": "Anti-Inflammatory High Fibre Diet",
            "kcal": 2200,
            "foods": [
                FoodItem(icon="🍅", name="Nyanya (cooked tomatoes)", benefit="Lycopene — prostate cancer protection", source="MOH p.71"),
                FoodItem(icon="🥬", name="Sukuma wiki / broccoli", benefit="Cruciferous — anti-cancer nutrients", source="MOH p.71"),
                FoodItem(icon="🐟", name="Samaki (oily fish)", benefit="Omega-3 — anti-inflammatory + selenium", source="MOH p.71"),
                FoodItem(icon="🫘", name="Beans", benefit="Fibre + zinc", source="MOH p.71"),
                FoodItem(icon="🫓", name="Ugali", benefit="Energy", source="MOH p.71"),
                FoodItem(icon="🥭", name="Matunda (fruits)", benefit="Antioxidants + Vitamin C", source="MOH p.71"),
                FoodItem(icon="🥜", name="Mbegu za malenge (pumpkin seeds)", benefit="Selenium + zinc", source="MOH p.71"),
            ],
            "avoid": ["Red/processed meat", "High-fat dairy", "Alcohol", "Excessive salt"],
            "source": "Kenya Nutrition Manual p.71 — lycopene from cooked tomatoes best absorbed; 2+ L water/day",
        },
    },

    # ══════════════════════════════════════════════════════════════════════════
    # 10. THYROIDECTOMY
    # Protocol: Modified C-Section + calcium protocol (hypocalcaemia risk)
    # ══════════════════════════════════════════════════════════════════════════
    "Thyroidectomy": {
        (1, 2): {
            "phase": "Soft Swallowing Diet (Neck Recovery)",
            "kcal": 800,
            "foods": [
                FoodItem(icon="🥣", name="Uji laini (smooth porridge)", benefit="Soft — no swallowing strain", source="MOH p.66"),
                FoodItem(icon="🫙", name="Mtindi (yoghurt)", benefit="Calcium — parathyroid risk", source="MOH p.66"),
                FoodItem(icon="🥛", name="Maziwa (milk)", benefit="Calcium 1200-1500 mg/day", source="MOH p.66"),
                FoodItem(icon="🍌", name="Ndizi iliyopondwa", benefit="Soft energy + potassium", source="MOH p.66"),
                FoodItem(icon="🥣", name="Supu laini (smooth soup)", benefit="Fluid + nutrients", source="MOH p.66"),
            ],
            "avoid": ["Hard/crunchy foods", "Very hot foods", "Fizzy drinks", "Foods requiring vigorous chewing"],
            "source": "Kenya Nutrition Manual p.66 — CRITICAL: monitor for hypocalcaemia (tingling lips/fingers = warning sign)",
        },
        (3, 7): {
            "phase": "High Calcium Soft Diet",
            "kcal": 1800,
            "foods": [
                FoodItem(icon="🥣", name="Uji with milk", benefit="Calcium + energy", source="MOH p.69"),
                FoodItem(icon="🐠", name="Omena (small fish)", benefit="Highest calcium food — parathyroid support", source="MOH p.69"),
                FoodItem(icon="🥚", name="Boiled eggs", benefit="Protein + selenium", source="MOH p.69"),
                FoodItem(icon="🍌", name="Ndizi (banana)", benefit="Potassium + energy", source="MOH p.69"),
                FoodItem(icon="🥭", name="Papai", benefit="Vitamin C + soft texture", source="MOH p.69"),
                FoodItem(icon="🥬", name="Sukuma wiki (well-cooked)", benefit="Calcium + iron", source="MOH p.69"),
            ],
            "avoid": ["Raw cabbage / raw cassava leaves (goitrogens)", "Very hard foods", "Excessive iodine supplements"],
            "source": "Kenya Nutrition Manual p.69 — Calcium 1200-1500 mg/day; Vitamin D3 800-2000 IU/day",
        },
        (8, 999): {
            "phase": "High Calcium Full Diet",
            "kcal": 2200,
            "foods": [
                FoodItem(icon="🐠", name="Omena (small fish with bones)", benefit="Calcium 1500 mg/day target", source="MOH p.75"),
                FoodItem(icon="🥛", name="Maziwa / mtindi", benefit="Calcium + Vitamin D", source="MOH p.75"),
                FoodItem(icon="🐟", name="Samaki (fish)", benefit="Selenium + iodine (cancer-free)", source="MOH p.75"),
                FoodItem(icon="🫓", name="Ugali (iodised salt in cooking)", benefit="Iodine source for thyroid", source="MOH p.75"),
                FoodItem(icon="🥬", name="Sukuma wiki", benefit="Vitamin K + calcium", source="MOH p.75"),
                FoodItem(icon="🥚", name="Eggs", benefit="Protein + selenium", source="MOH p.75"),
                FoodItem(icon="🍊", name="Machungwa", benefit="Vitamin C", source="MOH p.75"),
            ],
            "avoid": ["Large amounts raw cabbage/cassava (goitrogens)", "Taking levothyroxine with food (take 30-60 min before meals)"],
            "source": "Kenya Nutrition Manual p.75 — iodised salt recommended; cook goitrogenic foods (destroys goitrogen)",
        },
    },

    # ══════════════════════════════════════════════════════════════════════════
    # 11. KNEE REPLACEMENT (TKR)
    # Protocol: High protein musculoskeletal recovery (PMC/Nutrients 2021)
    # ══════════════════════════════════════════════════════════════════════════
    "Knee Replacement": {
        (1, 2): {
            "phase": "Clear Liquid Diet",
            "kcal": 500,
            "foods": [
                FoodItem(icon="💧", name="Water / ORS", benefit="Hydration", source="MOH p.66"),
                FoodItem(icon="🫖", name="Black tea", benefit="Hydration", source="MOH p.66"),
                FoodItem(icon="🥣", name="Clear broth", benefit="Electrolytes", source="MOH p.66"),
            ],
            "avoid": ["Solid food", "Alcohol", "Carbonated drinks"],
            "source": "Kenya Nutrition Manual p.66",
        },
        (3, 7): {
            "phase": "High Protein Calcium Soft Diet",
            "kcal": 2000,
            "foods": [
                FoodItem(icon="🥣", name="Uji with milk", benefit="Calcium + energy", source="MOH p.69"),
                FoodItem(icon="🥚", name="Eggs", benefit="Complete protein", source="MOH p.69"),
                FoodItem(icon="🐠", name="Omena", benefit="High calcium — bone support", source="MOH p.69"),
                FoodItem(icon="🫙", name="Mtindi (yoghurt)", benefit="Calcium + probiotics", source="MOH p.69"),
                FoodItem(icon="🍌", name="Ndizi (banana)", benefit="Potassium + energy", source="MOH p.69"),
            ],
            "avoid": ["Alcohol", "Smoking (impairs bone integration)", "Processed foods"],
            "source": "Kenya Nutrition Manual p.69 — protein 2 g/kg/day from Day 1; early mobilisation with physio",
        },
        (8, 999): {
            "phase": "High Protein Musculoskeletal Recovery Diet",
            "kcal": 2400,
            "foods": [
                FoodItem(icon="🍗", name="Kuku (chicken)", benefit="Muscle preservation 2 g/kg/day", source="MOH p.75"),
                FoodItem(icon="🐟", name="Samaki (fish)", benefit="Omega-3 — anti-inflammatory", source="MOH p.75"),
                FoodItem(icon="🥚", name="Eggs", benefit="Complete protein + Vitamin D", source="MOH p.75"),
                FoodItem(icon="🫘", name="Maharagwe (beans)", benefit="Plant protein + fibre", source="MOH p.75"),
                FoodItem(icon="🥛", name="Maziwa (milk)", benefit="Calcium for implant integration", source="MOH p.75"),
                FoodItem(icon="🐠", name="Omena", benefit="Calcium 1200 mg/day target", source="MOH p.75"),
                FoodItem(icon="🥬", name="Sukuma wiki", benefit="Vitamin K + iron", source="MOH p.75"),
            ],
            "avoid": ["Alcohol", "Smoking", "Excessive sugar", "Processed foods"],
            "source": "Kenya Nutrition Manual p.75 — PMC/Nutrients 2021: protein 2 g/kg/day; ONS reduces hospital cost by 12.2%",
        },
    },

    # ══════════════════════════════════════════════════════════════════════════
    # 12. HIP REPLACEMENT (THR)
    # Protocol: Modified C-Section + bone healing; sickle cell patients noted
    # ══════════════════════════════════════════════════════════════════════════
    "Hip Replacement": {
        (1, 2): {
            "phase": "Clear Liquid Diet",
            "kcal": 500,
            "foods": [
                FoodItem(icon="💧", name="Water / ORS (3 L/day sickle cell)", benefit="Hydration — extra for sickle cell patients", source="MOH p.66"),
                FoodItem(icon="🫖", name="Black tea", benefit="Hydration", source="MOH p.66"),
                FoodItem(icon="🥣", name="Clear broth", benefit="Electrolytes", source="MOH p.66"),
                FoodItem(icon="🧃", name="Strained juice", benefit="Vitamins", source="MOH p.66"),
            ],
            "avoid": ["Solid food", "Alcohol (causes AVN — stop permanently)", "Carbonated drinks"],
            "source": "Kenya Nutrition Manual p.66 — AVN most common indication for THR in Kenya (PMC 2019)",
        },
        (3, 7): {
            "phase": "High Protein Calcium Soft Diet",
            "kcal": 2000,
            "foods": [
                FoodItem(icon="🥣", name="Uji with milk", benefit="Calcium + energy", source="MOH p.69"),
                FoodItem(icon="🥚", name="Boiled eggs", benefit="Complete protein", source="MOH p.69"),
                FoodItem(icon="🐠", name="Omena (small fish)", benefit="Very high calcium — bone support", source="MOH p.69"),
                FoodItem(icon="🫙", name="Mtindi (yoghurt)", benefit="Calcium + probiotics", source="MOH p.69"),
                FoodItem(icon="🍌", name="Ndizi (banana)", benefit="Potassium", source="MOH p.69"),
            ],
            "avoid": ["Alcohol (major cause of AVN — critical to avoid permanently)", "Hard foods", "Smoking"],
            "source": "Kenya Nutrition Manual p.69",
        },
        (8, 999): {
            "phase": "High Protein Bone Healing Diet",
            "kcal": 2400,
            "foods": [
                FoodItem(icon="🐠", name="Omena (small fish with bones)", benefit="Calcium 1200 mg/day target", source="MOH p.75"),
                FoodItem(icon="🥛", name="Maziwa (milk)", benefit="Calcium + Vitamin D", source="MOH p.75"),
                FoodItem(icon="🍗", name="Kuku (chicken)", benefit="Protein 2 g/kg/day", source="MOH p.75"),
                FoodItem(icon="🐟", name="Samaki (fish)", benefit="Omega-3 anti-inflammatory", source="MOH p.75"),
                FoodItem(icon="🫘", name="Maharagwe (beans)", benefit="Iron (sickle cell) + protein", source="MOH p.75"),
                FoodItem(icon="🥬", name="Sukuma wiki", benefit="Iron + folate", source="MOH p.75"),
                FoodItem(icon="🫓", name="Ugali", benefit="Energy", source="MOH p.75"),
            ],
            "avoid": [
                "Alcohol (stop permanently — leading cause of AVN recurrence)",
                "Smoking",
                "Weight gain (excess BMI increases prosthesis wear)",
            ],
            "source": "Kenya Nutrition Manual p.75 — sickle cell patients: 3 L/day fluid, iron-rich diet; alcohol abstinence mandatory",
        },
    },

    # ══════════════════════════════════════════════════════════════════════════
    # 13. MASTECTOMY
    # Protocol: Modified C-Section + oncology nutrition
    # ══════════════════════════════════════════════════════════════════════════
    "Mastectomy": {
        (1, 1): {
            "phase": "Clear Liquid Diet",
            "kcal": 500,
            "foods": [
                FoodItem(icon="💧", name="Water / ORS", benefit="Hydration", source="MOH p.66"),
                FoodItem(icon="🫖", name="Black tea", benefit="Hydration", source="MOH p.66"),
                FoodItem(icon="🥣", name="Clear broth (supu)", benefit="Electrolytes", source="MOH p.66"),
                FoodItem(icon="🧃", name="Strained juice", benefit="Vitamin C + hydration", source="MOH p.66"),
            ],
            "avoid": ["Solid food", "Fatty/heavy foods", "Alcohol"],
            "source": "Kenya Nutrition Manual p.66",
        },
        (2, 14): {
            "phase": "High Protein Anti-Cancer Diet",
            "kcal": 2200,
            "foods": [
                FoodItem(icon="🐟", name="Samaki (oily fish 3×/week)", benefit="Omega-3 — immune recovery + anti-inflammatory", source="MOH p.69"),
                FoodItem(icon="🥚", name="Mayai (eggs)", benefit="Complete protein 1.5-2 g/kg/day", source="MOH p.69"),
                FoodItem(icon="🥬", name="Sukuma wiki / broccoli", benefit="Cruciferous — anti-cancer (sulforaphane)", source="MOH p.69"),
                FoodItem(icon="🍅", name="Nyanya (tomatoes)", benefit="Lycopene — antioxidant", source="MOH p.69"),
                FoodItem(icon="🥣", name="Uji / porridge", benefit="Easy-to-digest energy", source="MOH p.69"),
                FoodItem(icon="🍊", name="Machungwa (orange)", benefit="Vitamin C — antioxidant + immunity", source="MOH p.69"),
                FoodItem(icon="🫙", name="Mtindi (yoghurt)", benefit="Calcium + probiotics", source="MOH p.69"),
            ],
            "avoid": [
                "Alcohol (proven breast cancer recurrence risk)",
                "Processed/red meat (excess)",
                "Fried foods",
                "High-sodium foods (worsen lymphoedema)",
            ],
            "source": "Kenya Nutrition Manual p.69 — JCO Global Oncology 2017; immunonutrition pre-op reduces infectious complications",
        },
        (15, 999): {
            "phase": "Anti-Cancer Maintenance Diet",
            "kcal": 2400,
            "foods": [
                FoodItem(icon="🐟", name="Samaki / oily fish", benefit="Omega-3 anti-cancer + anti-inflammatory", source="MOH p.75"),
                FoodItem(icon="🥬", name="Sukuma wiki / broccoli / spinach", benefit="Cruciferous anti-cancer vegetables", source="MOH p.75"),
                FoodItem(icon="🍅", name="Nyanya za kupika (cooked tomatoes)", benefit="Lycopene better absorbed when cooked", source="MOH p.75"),
                FoodItem(icon="🫘", name="Beans / lentils (dengu)", benefit="Fibre + plant protein", source="MOH p.75"),
                FoodItem(icon="🫓", name="Ugali", benefit="Energy", source="MOH p.75"),
                FoodItem(icon="🥛", name="Maziwa / mtindi", benefit="Calcium + Vitamin D (if hormone therapy)", source="MOH p.75"),
                FoodItem(icon="🥭", name="Matunda ya rangi (colourful fruits)", benefit="Antioxidants (Vit C, E, beta-carotene)", source="MOH p.75"),
            ],
            "avoid": [
                "Alcohol (proven recurrence risk)",
                "Processed/red meat (limit)",
                "High-fat dairy",
                "High-sodium foods (lymphoedema)",
                "Excessive sugar",
            ],
            "source": "Kenya Nutrition Manual p.75 — 1.5-2 g protein/kg/day especially if chemotherapy follows",
        },
    },

    # ══════════════════════════════════════════════════════════════════════════
    # 14. MYOMECTOMY
    # Protocol: Modified C-Section + anti-fibroid / high-iron nutrition
    # Key concern: perioperative blood loss → iron-deficiency anaemia
    # ══════════════════════════════════════════════════════════════════════════
    "Myomectomy": {
        (1, 3): {
            "phase": "High Iron Liquid/Soft Diet (Blood Loss Recovery)",
            "kcal": 1200,
            "foods": [
                FoodItem(icon="🧃", name="Mchuzi wa machungwa (orange juice)", benefit="Vitamin C — enhances iron absorption", source="MOH p.66"),
                FoodItem(icon="🥣", name="Uji (iron-fortified flour)", benefit="Iron + energy", source="MOH p.66"),
                FoodItem(icon="💧", name="Water / ORS", benefit="Hydration + electrolytes", source="MOH p.66"),
                FoodItem(icon="🥣", name="Supu ya nyama (meat broth)", benefit="Iron + protein", source="MOH p.66"),
                FoodItem(icon="🫖", name="Black tea (between meals)", benefit="Hydration — NOT with food (blocks iron)", source="MOH p.66"),
            ],
            "avoid": [
                "Tea/coffee with meals (tannins block iron absorption)",
                "Milk with iron-rich meals (calcium competes with iron)",
                "Solid foods initially",
            ],
            "source": "Kenya Nutrition Manual p.66 — heavy perioperative blood loss; iron supplementation critical",
        },
        (4, 7): {
            "phase": "High Iron High Protein Soft Diet",
            "kcal": 2000,
            "foods": [
                FoodItem(icon="🥩", name="Nyama nyekundu kidogo (small red meat)", benefit="Haem iron — most absorbable form", source="MOH p.69"),
                FoodItem(icon="🐟", name="Samaki (fish)", benefit="Protein + non-haem iron", source="MOH p.69"),
                FoodItem(icon="🥚", name="Boiled eggs", benefit="Protein + iron", source="MOH p.69"),
                FoodItem(icon="🥬", name="Mchicha (spinach)", benefit="Non-haem iron + folate", source="MOH p.69"),
                FoodItem(icon="🍊", name="Machungwa (orange) with meals", benefit="Vitamin C doubles iron absorption", source="MOH p.69"),
                FoodItem(icon="🫓", name="Ugali laini", benefit="Energy", source="MOH p.69"),
            ],
            "avoid": [
                "Tea/coffee within 1 hour of meals (blocks iron)",
                "Raw vegetables",
                "Hard/tough foods",
            ],
            "source": "Kenya Nutrition Manual p.69 — 1.5 g protein/kg/day for uterine repair",
        },
        (8, 999): {
            "phase": "High Iron Anti-Oestrogen Full Diet",
            "kcal": 2500,
            "foods": [
                FoodItem(icon="🫘", name="Maharagwe + machungwa", benefit="Iron + Vitamin C combination critical", source="MOH p.75"),
                FoodItem(icon="🥬", name="Sukuma wiki / mchicha (spinach)", benefit="Iron + folate + anti-oestrogen phytochemicals", source="MOH p.75"),
                FoodItem(icon="🥦", name="Broccoli / kabichi (cruciferous)", benefit="Anti-oestrogenic — supports oestrogen metabolism", source="MOH p.75"),
                FoodItem(icon="🐟", name="Samaki (fish)", benefit="Omega-3 anti-inflammatory + protein", source="MOH p.75"),
                FoodItem(icon="🫓", name="Ugali", benefit="Energy", source="MOH p.75"),
                FoodItem(icon="🥬", name="Mbegu za kitani (flaxseed)", benefit="Phytoestrogens — modest fibroid benefit", source="MOH p.75"),
                FoodItem(icon="🍊", name="Matunda ya Vitamin C with every iron meal", benefit="Iron absorption — critical rule", source="MOH p.75"),
            ],
            "avoid": [
                "Tea/coffee immediately after meals",
                "Excessive red meat",
                "High-fat dairy (pro-oestrogenic)",
                "Alcohol (pro-oestrogenic)",
            ],
            "source": "Kenya Nutrition Manual p.75 — Vitamin D deficiency linked to fibroid risk; cruciferous veg support oestrogen clearance",
        },
    },

    # ══════════════════════════════════════════════════════════════════════════
    # 15. CARDIAC SURGERY (CABG, Valve Replacement, Congenital Repair)
    # Protocol: Cardiac-specific; low sodium; Tenwek/AKUH Nairobi context
    # ══════════════════════════════════════════════════════════════════════════
    "Cardiac Surgery": {
        (1, 3): {
            "phase": "Cardiac Clear/Liquid Diet (ICU Recovery)",
            "kcal": 800,
            "foods": [
                FoodItem(icon="💧", name="Water (restricted: 1.5 L/day)", benefit="Fluid balance — heart failure risk", source="MOH p.66"),
                FoodItem(icon="🫖", name="Black tea (no sugar, no milk)", benefit="Zero sodium, zero fat", source="MOH p.66"),
                FoodItem(icon="🥣", name="Clear broth (low sodium)", benefit="Electrolytes — NO table salt", source="MOH p.66"),
                FoodItem(icon="🧃", name="Strained juice (small portions)", benefit="Potassium + Vitamin C", source="MOH p.66"),
            ],
            "avoid": [
                "Salt / sodium-rich foods",
                "Fried foods / fatty foods",
                "Alcohol",
                "Solid food (if still ventilated)",
                "Coconut oil / ghee",
            ],
            "source": "Kenya Nutrition Manual p.66 — cardiac ICU: enteral nutrition via NGT if ventilation prolonged",
        },
        (4, 14): {
            "phase": "Cardiac Soft Diet (Low Sodium / Low Saturated Fat)",
            "kcal": 1800,
            "foods": [
                FoodItem(icon="🥣", name="Uji (no fat, no salt)", benefit="Low sodium energy", source="MOH p.69"),
                FoodItem(icon="🥚", name="Boiled egg white", benefit="Protein — no saturated fat in white", source="MOH p.69"),
                FoodItem(icon="🐟", name="Steamed fish (dagaa/samaki)", benefit="Omega-3 — anti-arrhythmic", source="MOH p.69"),
                FoodItem(icon="🍌", name="Ndizi (banana)", benefit="Potassium — monitor if on diuretics", source="MOH p.69"),
                FoodItem(icon="🥑", name="Avokado (small portion)", benefit="Potassium + healthy fats", source="MOH p.69"),
                FoodItem(icon="🥬", name="Mboga za kuchemsha (no salt)", benefit="Potassium + magnesium", source="MOH p.69"),
            ],
            "avoid": [
                "Salt (strictly <2 g/day)",
                "Butter / ghee / coconut oil (saturated fat)",
                "Fatty / processed meats",
                "Alcohol",
                "High-sodium processed foods",
                "Full-fat dairy",
            ],
            "source": "Kenya Nutrition Manual p.69 — warfarin patients: consistent Vitamin K intake (NOT low — consistent)",
        },
        (15, 999): {
            "phase": "Mediterranean Cardiac Diet (Long-term)",
            "kcal": 2200,
            "foods": [
                FoodItem(icon="🐟", name="Sardini / makrill (sardines / mackerel)", benefit="Omega-3 — anti-arrhythmic, 3×/week", source="MOH p.75"),
                FoodItem(icon="🥬", name="Sukuma wiki / mboga za kijani", benefit="Potassium + magnesium + folate", source="MOH p.75"),
                FoodItem(icon="🫘", name="Beans / dengu (lentils)", benefit="Fibre + protein — heart-protective", source="MOH p.75"),
                FoodItem(icon="🍠", name="Viazi vitamu (sweet potatoes)", benefit="Potassium + Vitamin A", source="MOH p.75"),
                FoodItem(icon="🍌", name="Ndizi / avokado", benefit="Potassium — cardiac muscle function", source="MOH p.75"),
                FoodItem(icon="🫓", name="Ugali (small portion)", benefit="Energy", source="MOH p.75"),
                FoodItem(icon="🥭", name="Matunda (colourful fruits)", benefit="Antioxidants + potassium", source="MOH p.75"),
            ],
            "avoid": [
                "Salt strictly (<2 g/day — lifelong)",
                "Saturated fats (butter, ghee, coconut oil, fatty meat)",
                "Alcohol (arrhythmia risk)",
                "Processed / fast foods",
                "Excessive caffeine",
            ],
            "source": "Kenya Nutrition Manual p.75 — sternal wound: 1.5-2 g protein/kg/day; JACC Advances 2024 (Tenwek model)",
        },
    },
}

# ─────────────────────────────────────────────────────────────────────────────
# ALLERGY EXCLUSIONS
# Maps allergy category → set of food names to remove from recommendations
# ─────────────────────────────────────────────────────────────────────────────
ALLERGY_EXCLUSIONS: dict[str, set[str]] = {
    "Milk/Dairy": {
        "Maziwa (milk)", "Maziwa / mtindi", "Uji with milk", "Uji with milk", "Mtindi (yoghurt)",
        "Milk", "Full cream milk", "Maziwa / mtindi", "Low-fat milk", "Maziwa (milk)",
        "Uji with milk",
    },
    "Eggs": {
        "Mayai (eggs)", "Boiled eggs", "Scrambled eggs", "Eggs",
        "Boiled eggs (no yolk)", "Boiled egg white", "Mayai ya kuchemsha",
    },
    "Peanuts": {"Peanuts", "Groundnuts"},
    "Soya":    {"Soya", "Soy milk"},
    "Seafood": {
        "Samaki (fish)", "Samaki (oily fish 3×/week)", "Samaki wa kuchemsha",
        "Steamed fish", "Steamed fish (dagaa/samaki)", "Steamed / boiled fish",
        "Fresh Fish (Samaki)", "Samaki / oily fish",
        "Omena (small fish with bones)", "Omena (small fish)", "Omena",
        "Sardini / makrill (sardines / mackerel)",
        "Dagaa / samaki", "Samaki (dagaa/samaki)",
        "Oily fish", "Fish",
    },
    "Tree Nuts": {"Mbegu za malenge (pumpkin seeds)"},
}


class DietEngine:
    """
    Surgery-aware diet recommendation engine.

    Usage:
        engine = DietEngine()
        plan = engine.get_plan("Hysterectomy", day=5, allergies=["Eggs"])
        # Returns DietResponse with phase, foods, key_nutrients, etc.
    """

    def _normalize(self, surgery_type: str) -> str:
        """Resolve name variants to the canonical key used in SURGICAL_DIET_PROGRESSION."""
        # Exact match first
        if surgery_type in SURGICAL_DIET_PROGRESSION:
            return surgery_type
        # Alias lookup
        if surgery_type in SURGERY_NAME_ALIASES:
            return SURGERY_NAME_ALIASES[surgery_type]
        # Case-insensitive fallback
        lower = surgery_type.lower()
        for canonical in SURGICAL_DIET_PROGRESSION:
            if canonical.lower() == lower:
                return canonical
        for alias, canonical in SURGERY_NAME_ALIASES.items():
            if alias.lower() == lower:
                return canonical
        # Unknown surgery — default to Caesarean (most detailed general abdominal protocol)
        return "Caesarean Section"

    def get_plan(
        self,
        surgery_type: str,
        day: int,
        allergies: list[str] | None = None,
    ) -> DietResponse:
        """
        Get the diet plan for a specific surgery type and recovery day.
        Filters out foods the patient is allergic to.

        Args:
            surgery_type: Surgery name (normalised automatically — 15 types supported).
            day:          Recovery day number (1 = first day after surgery).
            allergies:    List of allergy category strings e.g. ["Milk/Dairy", "Eggs"].

        Returns:
            DietResponse with phase, foods, avoid list, key_nutrients, calorie target.
        """
        canonical = self._normalize(surgery_type)
        progression = SURGICAL_DIET_PROGRESSION[canonical]

        # Find the correct phase for this day
        phase_data = None
        for (day_start, day_end), data in progression.items():
            if day_start <= day <= day_end:
                phase_data = data
                break

        # Default to last phase if day exceeds all ranges (shouldn't happen with 999 end)
        if not phase_data:
            phase_data = list(progression.values())[-1]

        # Filter out allergens
        foods = phase_data["foods"]
        if allergies:
            excluded_foods: set[str] = set()
            for allergy in allergies:
                excluded_foods.update(ALLERGY_EXCLUSIONS.get(allergy, set()))
            foods = [f for f in foods if f.name not in excluded_foods]

        return DietResponse(
            day=day,
            phase=phase_data["phase"],
            target_kcal=phase_data["kcal"],
            foods=foods,
            avoid=phase_data["avoid"],
            source=phase_data["source"],
            key_nutrients=SURGERY_KEY_NUTRIENTS.get(canonical, ""),
        )
