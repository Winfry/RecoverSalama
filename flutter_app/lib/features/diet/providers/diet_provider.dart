import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single food item
class FoodItem {
  final String icon;
  final String name;
  final String benefit;
  final int calories;

  const FoodItem({
    required this.icon,
    required this.name,
    required this.benefit,
    this.calories = 0,
  });
}

/// A food category (Protein, Energy, etc.)
class FoodCategory {
  final String name;
  final String icon;
  final List<FoodItem> foods;

  const FoodCategory({
    required this.name,
    required this.icon,
    required this.foods,
  });
}

/// Diet state — holds current day's recommendations
class DietState {
  final int currentDay;
  final String dietPhase;
  final String aiTip;
  final List<FoodCategory> categories;

  const DietState({
    this.currentDay = 5,
    this.dietPhase = 'Soft Diet',
    this.aiTip = 'AI Tip: Pair ugali with beans for complete protein',
    this.categories = const [],
  });
}

class DietNotifier extends StateNotifier<DietState> {
  DietNotifier()
      : super(const DietState(
          categories: [
            // Kenya-local foods from MOH Clinical Nutrition Manual
            FoodCategory(
              name: 'Protein',
              icon: '💪',
              foods: [
                FoodItem(
                  icon: '🥚',
                  name: 'Eggs (Mayai)',
                  benefit: 'Complete protein for tissue repair',
                  calories: 155,
                ),
                FoodItem(
                  icon: '🫘',
                  name: 'Beans (Githeri)',
                  benefit: 'High fibre & protein',
                  calories: 347,
                ),
                FoodItem(
                  icon: '🐟',
                  name: 'Fresh Fish (Samaki)',
                  benefit: 'Omega-3 supports healing',
                  calories: 206,
                ),
                FoodItem(
                  icon: '🍗',
                  name: 'Chicken (Kuku)',
                  benefit: 'Lean protein source',
                  calories: 239,
                ),
              ],
            ),
            FoodCategory(
              name: 'Energy',
              icon: '⚡',
              foods: [
                FoodItem(
                  icon: '🫓',
                  name: 'Ugali',
                  benefit: 'Slow-release energy',
                  calories: 385,
                ),
                FoodItem(
                  icon: '🍠',
                  name: 'Sweet Potatoes (Viazi)',
                  benefit: 'Vitamin A & energy',
                  calories: 86,
                ),
                FoodItem(
                  icon: '🍌',
                  name: 'Bananas (Ndizi)',
                  benefit: 'Potassium & quick energy',
                  calories: 89,
                ),
              ],
            ),
            FoodCategory(
              name: 'Vitamins',
              icon: '🥬',
              foods: [
                FoodItem(
                  icon: '🥬',
                  name: 'Sukuma Wiki (Kale)',
                  benefit: 'Iron & Vitamin K',
                  calories: 49,
                ),
                FoodItem(
                  icon: '🥭',
                  name: 'Pawpaw (Papai)',
                  benefit: 'Vitamin C for wound healing',
                  calories: 43,
                ),
                FoodItem(
                  icon: '🥑',
                  name: 'Avocado',
                  benefit: 'Healthy fats & Vitamin E',
                  calories: 160,
                ),
              ],
            ),
            FoodCategory(
              name: 'Fluids',
              icon: '💧',
              foods: [
                FoodItem(
                  icon: '🥣',
                  name: 'Uji wa Wimbi',
                  benefit: 'High protein porridge',
                  calories: 350,
                ),
                FoodItem(
                  icon: '🫖',
                  name: 'Warm Water & Lemon',
                  benefit: 'Hydration & digestion',
                  calories: 5,
                ),
                FoodItem(
                  icon: '🥛',
                  name: 'Mtindi (Yoghurt)',
                  benefit: 'Probiotics & calcium',
                  calories: 100,
                ),
              ],
            ),
          ],
        ));

  // TODO: Fetch personalised diet from backend based on:
  // - Surgery type
  // - Recovery day
  // - Patient allergies
  // - Kenya Nutrition Manual surgical diet progression table
}

final dietProvider = StateNotifierProvider<DietNotifier, DietState>((ref) {
  return DietNotifier();
});
