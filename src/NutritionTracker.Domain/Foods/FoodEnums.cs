namespace NutritionTracker.Domain.Foods;

public enum FoodCategory { Grain, Pulse, Vegetable, Fruit, Dairy, Egg, Meat, Poultry, Fish, Seafood, Nut, Seed, Oil, Sweet, Beverage, Snack, PreparedDish, Condiment, Spice, Other }
public enum Cuisine { General, Bengali, NorthIndian, SouthIndian, Punjabi, Gujarati, Maharashtrian, Odia, Assamese, Kerala, IndoChinese, International, Unknown }
public enum PreparationMethod { Raw, Boiled, Steamed, Fried, DeepFried, ShallowFried, Grilled, Roasted, Baked, Sauteed, Curried, Fermented, Dried, Mixed, Unknown }
public enum FoodState { Raw, Cooked, Prepared, Packaged, Unknown }
public enum AliasType { CommonName, RegionalName, Translation, Transliteration, AlternativeSpelling, BrandName, Abbreviation }
public enum ServingUnitType { Mass, Volume, Count, HouseholdMeasure, DishSpecific }
public enum DataConfidence { Low, Medium, High, Verified }
