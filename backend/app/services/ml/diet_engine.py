"""
Diet Engine — surgery-specific meal plans from Kenya Nutrition Manual.

This is a rules-based engine (not ML) because the diet progression
is a well-defined clinical protocol from the Kenya National Clinical
Nutrition and Dietetics Reference Manual (MOH, 2010).

How it works:
1. Takes surgery_type + recovery_day + patient_allergies as input
2. Looks up the correct diet phase from SURGICAL_DIET_PROGRESSION
3. Filters out allergens
4. Returns Kenya-local food recommendations with calorie targets

The progression is:
- Day 1-2: Clear liquid diet (black tea, clear broth, water)
- Day 3-4: Full liquid diet (uji, milk, yoghurt, soup)
- Day 5-7: Soft diet (ugali laini, eggs, banana, pawpaw)
- Day 8+:  High protein diet (ugali, beans, fish, chicken, sukuma wiki)

Each surgery type has its own variations:
- Cholecystectomy → fat restricted throughout (≤25g fat/day)
- Hernia → high fibre from Day 5 (prevent constipation straining)
- Appendectomy → low fibre first, then high fibre
"""

from app.schemas.recovery import DietResponse, FoodItem

# Source: Kenya National Clinical Nutrition Manual, MOH 2010
SURGICAL_DIET_PROGRESSION = {
    "Caesarean Section": {
        (1, 2): {
            "phase": "Clear Liquid Diet",
            "kcal": 500,
            "foods": [
                FoodItem(icon="🫖", name="Black tea (no milk)", benefit="Hydration", source="MOH p.66"),
                FoodItem(icon="🥣", name="Clear broth (supu)", benefit="Electrolytes", source="MOH p.66"),
                FoodItem(icon="🧃", name="Strained juice", benefit="Vitamins", source="MOH p.66"),
                FoodItem(icon="💧", name="Water", benefit="Hydration", source="MOH p.66"),
            ],
            "avoid": ["Milk", "Solid food", "Carbonated drinks"],
            "source": "Kenya Nutrition Manual p.66",
        },
        (3, 4): {
            "phase": "Full Liquid Diet",
            "kcal": 1500,
            "foods": [
                FoodItem(icon="🥣", name="Uji wa unga", benefit="Energy + easy digestion", source="MOH p.67"),
                FoodItem(icon="🥛", name="Maziwa (milk)", benefit="Calcium + protein", source="MOH p.67"),
                FoodItem(icon="🫙", name="Mtindi (yoghurt)", benefit="Probiotics", source="MOH p.67"),
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
            "avoid": ["Excessive sugar", "Processed foods"],
            "source": "Kenya Nutrition Manual p.75 — 35-40 kcal/kg, 2:1 protein ratio",
        },
    },
    "Appendectomy": {
        (1, 2): {
            "phase": "Clear Liquid Diet",
            "kcal": 500,
            "foods": [
                FoodItem(icon="🫖", name="Black tea", benefit="Hydration", source="MOH p.66"),
                FoodItem(icon="🥣", name="Clear broth", benefit="Electrolytes", source="MOH p.66"),
                FoodItem(icon="💧", name="Water", benefit="Hydration", source="MOH p.66"),
            ],
            "avoid": ["Milk", "Solid food", "High fibre foods"],
            "source": "Kenya Nutrition Manual p.66",
        },
        (3, 5): {
            "phase": "Low Fibre Soft Diet",
            "kcal": 1500,
            "foods": [
                FoodItem(icon="🥣", name="Uji", benefit="Easy digestion", source="MOH p.69"),
                FoodItem(icon="🥚", name="Boiled eggs", benefit="Protein", source="MOH p.69"),
                FoodItem(icon="🍌", name="Ripe banana", benefit="Gentle on stomach", source="MOH p.69"),
            ],
            "avoid": ["High fibre foods", "Raw vegetables", "Beans"],
            "source": "Kenya Nutrition Manual p.69",
        },
        (6, 999): {
            "phase": "High Fibre Normal Diet",
            "kcal": 2200,
            "foods": [
                FoodItem(icon="🫘", name="Githeri", benefit="Fibre + protein", source="MOH p.71"),
                FoodItem(icon="🥬", name="Sukuma wiki", benefit="Fibre + iron", source="MOH p.71"),
                FoodItem(icon="🫓", name="Ugali", benefit="Energy", source="MOH p.71"),
                FoodItem(icon="🍠", name="Sweet potatoes", benefit="Fibre + Vitamin A", source="MOH p.71"),
            ],
            "avoid": ["Excessive spicy food"],
            "source": "Kenya Nutrition Manual p.71",
        },
    },
    "Hernia Repair": {
        (1, 3): {
            "phase": "Soft Low Fibre Diet",
            "kcal": 1500,
            "foods": [
                FoodItem(icon="🥣", name="Uji", benefit="Easy digestion", source="MOH p.69"),
                FoodItem(icon="🥚", name="Scrambled eggs", benefit="Soft protein", source="MOH p.69"),
                FoodItem(icon="🍌", name="Banana mash", benefit="Gentle energy", source="MOH p.69"),
            ],
            "avoid": ["High fibre", "Beans", "Raw vegetables"],
            "source": "Kenya Nutrition Manual p.69",
        },
        (4, 999): {
            "phase": "High Fibre Diet",
            "kcal": 2200,
            "foods": [
                FoodItem(icon="🫘", name="Beans (maharagwe)", benefit="Fibre prevents straining", source="MOH p.71"),
                FoodItem(icon="🥬", name="Sukuma wiki", benefit="Fibre + vitamins", source="MOH p.71"),
                FoodItem(icon="🍠", name="Sweet potatoes", benefit="Gentle fibre", source="MOH p.71"),
                FoodItem(icon="🥭", name="Papaya", benefit="Digestive enzymes", source="MOH p.71"),
            ],
            "avoid": ["Straining foods", "Excessive dairy"],
            "source": "Kenya Nutrition Manual p.71 — high fibre to prevent constipation straining on wound",
        },
    },
    "Cholecystectomy": {
        (1, 999): {
            "phase": "Fat Restricted Diet",
            "kcal": 1800,
            "foods": [
                FoodItem(icon="🥣", name="Uji (no butter)", benefit="Low fat energy", source="MOH p.74"),
                FoodItem(icon="🥚", name="Boiled eggs (no yolk)", benefit="Lean protein", source="MOH p.74"),
                FoodItem(icon="🐟", name="Steamed fish", benefit="Low fat protein", source="MOH p.74"),
                FoodItem(icon="🍌", name="Fruits", benefit="Vitamins, zero fat", source="MOH p.74"),
                FoodItem(icon="🥬", name="Steamed vegetables", benefit="Fibre, no fat", source="MOH p.74"),
            ],
            "avoid": ["Fried foods", "Butter", "Full cream milk", "Avocado", "Fatty meat"],
            "source": "Kenya Nutrition Manual p.74 — max 25g fat per day",
        },
    },
    "Knee Replacement": {
        (1, 999): {
            "phase": "High Protein Diet",
            "kcal": 2400,
            "foods": [
                FoodItem(icon="🍗", name="Kuku (chicken)", benefit="Muscle preservation", source="MOH p.75"),
                FoodItem(icon="🐟", name="Samaki (fish)", benefit="Omega-3 + protein", source="MOH p.75"),
                FoodItem(icon="🥚", name="Eggs", benefit="Complete protein", source="MOH p.75"),
                FoodItem(icon="🫘", name="Beans", benefit="Plant protein", source="MOH p.75"),
                FoodItem(icon="🥛", name="Milk", benefit="Calcium for bones", source="MOH p.75"),
            ],
            "avoid": ["Excessive sugar", "Processed foods"],
            "source": "Kenya Nutrition Manual p.75 — 2:1 protein ratio to counter muscle atrophy",
        },
    },
}

# Allergy mappings — which foods to exclude per allergy
ALLERGY_EXCLUSIONS = {
    "Milk/Dairy": {"Maziwa (milk)", "Mtindi (yoghurt)", "Milk", "Full cream milk"},
    "Eggs": {"Mayai (eggs)", "Boiled eggs", "Scrambled eggs", "Eggs", "Boiled eggs (no yolk)"},
    "Peanuts": {"Peanuts", "Groundnuts"},
    "Soya": {"Soya", "Soy milk"},
    "Seafood": {"Samaki (fish)", "Fresh Fish (Samaki)", "Steamed fish"},
}


class DietEngine:
    def get_plan(
        self,
        surgery_type: str,
        day: int,
        allergies: list[str] | None = None,
    ) -> DietResponse:
        """
        Get the diet plan for a specific surgery type and recovery day.
        Filters out foods the patient is allergic to.
        """
        progression = SURGICAL_DIET_PROGRESSION.get(surgery_type)

        if not progression:
            # Default to caesarean progression if surgery type not found
            progression = SURGICAL_DIET_PROGRESSION["Caesarean Section"]

        # Find the right phase for this day
        phase_data = None
        for (day_start, day_end), data in progression.items():
            if day_start <= day <= day_end:
                phase_data = data
                break

        if not phase_data:
            # Default to the last phase
            phase_data = list(progression.values())[-1]

        # Filter out allergens
        foods = phase_data["foods"]
        if allergies:
            excluded_foods = set()
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
        )
