using NutritionTracker.Domain.Profiles;

namespace NutritionTracker.Application.Nutrition;

/// <summary>Calculates BMR with the Mifflin-St Jeor equation and applies the configured non-medical target policy.</summary>
public sealed class MifflinStJeorNutritionTargetCalculator(NutritionCalculationOptions options) : INutritionTargetCalculator
{
    public NutritionTargetResult Calculate(NutritionTargetInput input)
    {
        var age = CalculateAge(input.DateOfBirth, input.EffectiveDate);
        if (age < options.MinimumSupportedAge || age > options.MaximumSupportedAge)
            throw new NutritionCalculationException("The date of birth is outside the supported calculation age range.");

        if (input.GoalType == GoalType.Custom)
            return CalculateCustom(input, age);
        if (input.BiologicalSex == BiologicalSex.Unspecified)
            throw new NutritionCalculationException("Automatic calculation requires a supported biological sex selection. Use custom targets instead.");

        var bmr = input.BiologicalSex == BiologicalSex.Male
            ? (10m * input.CurrentWeightKg) + (6.25m * input.HeightCm) - (5m * age) + 5m
            : (10m * input.CurrentWeightKg) + (6.25m * input.HeightCm) - (5m * age) - 161m;
        var tdee = bmr * Get(options.ActivityMultipliers, input.ActivityLevel, "activity multiplier");
        var target = tdee + Get(options.GoalCalorieAdjustments, input.GoalType, "goal adjustment");
        var warnings = new List<string>();
        var minimum = input.BiologicalSex == BiologicalSex.Male ? options.MinimumCaloriesMale : options.MinimumCaloriesFemale;
        if (target < minimum) { target = minimum; warnings.Add("The automatic calorie target was raised to the configured application safeguard. This is not medical advice."); }

        var protein = input.CurrentWeightKg * Get(options.ProteinMultipliers, input.GoalType, "protein multiplier");
        var fat = Math.Max((target * options.FatPercentage) / 9m, input.CurrentWeightKg * options.MinimumFatGramsPerKg);
        var carbohydrateCalories = target - (protein * 4m) - (fat * 9m);
        if (carbohydrateCalories < 0m) throw new NutritionCalculationException("Configured protein and fat targets exceed the calorie target.");
        var carbohydrates = carbohydrateCalories / 4m;
        return Result(age, bmr, tdee, target, protein, carbohydrates, fat, options.FibreGramsPer1000Calories * target / 1000m, "Mifflin-St Jeor", warnings);
    }

    private NutritionTargetResult CalculateCustom(NutritionTargetInput input, int age)
    {
        if (input.CustomCalories is null || input.CustomProteinGrams is null || input.CustomCarbohydrateGrams is null || input.CustomFatGrams is null)
            throw new NutritionCalculationException("Custom targets require calories, protein, carbohydrates, and fat.");
        if (input.CustomCalories <= 0 || input.CustomProteinGrams < 0 || input.CustomCarbohydrateGrams < 0 || input.CustomFatGrams < 0)
            throw new NutritionCalculationException("Custom targets must be non-negative and calories must be positive.");
        var macroCalories = input.CustomProteinGrams.Value * 4m + input.CustomCarbohydrateGrams.Value * 4m + input.CustomFatGrams.Value * 9m;
        if (Math.Abs(macroCalories - input.CustomCalories.Value) > options.MacroCalorieTolerance)
            throw new NutritionCalculationException("Custom macro calories must reconcile with target calories within the configured tolerance.");
        return Result(age, 0m, 0m, input.CustomCalories.Value, input.CustomProteinGrams.Value, input.CustomCarbohydrateGrams.Value, input.CustomFatGrams.Value, options.FibreGramsPer1000Calories * input.CustomCalories.Value / 1000m, "Custom", ["Custom targets are user supplied and are not adjusted by application safeguards."]);
    }

    private static int CalculateAge(DateOnly birthDate, DateOnly onDate)
    {
        if (birthDate > onDate) throw new NutritionCalculationException("Date of birth must be in the past.");
        var age = onDate.Year - birthDate.Year;
        return birthDate > onDate.AddYears(-age) ? age - 1 : age;
    }

    private static decimal Get<T>(IReadOnlyDictionary<T, decimal> values, T key, string name) where T : notnull => values.TryGetValue(key, out var value) ? value : throw new NutritionCalculationException($"Missing configured {name}.");
    private static NutritionTargetResult Result(int age, decimal bmr, decimal tdee, decimal calories, decimal protein, decimal carbs, decimal fat, decimal fibre, string method, IReadOnlyList<string> warnings) => new(age, Round(bmr), Round(tdee), Round(calories), Round(protein), Round(carbs), Round(fat), Round(fibre), method, warnings);
    private static decimal Round(decimal value) => decimal.Round(value, 2, MidpointRounding.AwayFromZero);
}
