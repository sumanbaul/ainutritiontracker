using System.Diagnostics;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using NutritionTracker.Application.Foods;
using NutritionTracker.Application.MealVision;
using NutritionTracker.Domain.Foods;
namespace NutritionTracker.Infrastructure.MealVision;

public sealed class MealVisionOptions
{
    public const string SectionName = "MealVision"; public MealVisionProviderKind Provider { get; init; } = MealVisionProviderKind.Mock; public string PromptVersion { get; init; } = "v1"; public string SchemaVersion { get; init; } = "1.0"; public int RequestTimeoutSeconds { get; init; } = 30; public int MaximumImageBytes { get; init; } = 5_000_000; public int MaximumItems { get; init; } = 20; public decimal MinimumRecognitionConfidence { get; init; } = .75m; public decimal MinimumPortionConfidence { get; init; } = .65m; public bool EnableClarificationQuestions { get; init; } = true; public bool EnableAlternativeCandidates { get; init; } = true; public bool EnableRawResponsePersistence { get; init; }
    public bool AllowMockInProduction { get; init; }
    public MockMealVisionOptions Mock { get; init; } = new();
    public OpenAiMealVisionOptions OpenAi { get; init; } = new();
    public GeminiMealVisionOptions Gemini { get; init; } = new();
    public AnthropicMealVisionOptions Anthropic { get; init; } = new();
    public OllamaMealVisionOptions Ollama { get; init; } = new();
    public OpenAiCompatibleMealVisionOptions OpenAiCompatible { get; init; } = new();
}
public sealed class MockMealVisionOptions { public string Scenario { get; init; } = "BengaliLunch"; public int DelayMilliseconds { get; init; } public bool ForceMalformedResponse { get; init; } public bool ForceTimeout { get; init; } public bool ForceProviderFailure { get; init; } }
public sealed class OpenAiMealVisionOptions
{
    public bool Enabled { get; init; } = true;
    public string Endpoint { get; init; } = "https://api.openai.com/v1/";
    public string Model { get; init; } = "gpt-5.4-mini";
    public string? ApiKey { get; init; }
    public string ImageDetail { get; init; } = "low";
    public int MaxOutputTokens { get; init; } = 2_000;
}
public abstract class ConfiguredMealVisionOptions
{
    public virtual bool Enabled { get; init; }
    public virtual string Endpoint { get; init; } = string.Empty;
    public string? ApiKey { get; init; }
    public virtual string Model { get; init; } = string.Empty;
    public List<string> AllowedModels { get; init; } = [];
    public int MaxOutputTokens { get; init; } = 2_000;
}
public sealed class GeminiMealVisionOptions : ConfiguredMealVisionOptions { public override string Endpoint { get; init; } = "https://generativelanguage.googleapis.com/v1beta/"; public override string Model { get; init; } = "gemini-2.5-flash"; }
public sealed class AnthropicMealVisionOptions : ConfiguredMealVisionOptions { public override string Endpoint { get; init; } = "https://api.anthropic.com/"; public override string Model { get; init; } = "claude-sonnet-4-5"; }
public sealed class OllamaMealVisionOptions : ConfiguredMealVisionOptions { public override string Endpoint { get; init; } = "http://127.0.0.1:11434/"; public override string Model { get; init; } = "gemma3:4b"; public override bool Enabled { get; init; } = true; }
public sealed class OpenAiCompatibleMealVisionOptions : ConfiguredMealVisionOptions { }
public sealed class MockMealVisionProvider(IOptions<MealVisionOptions> options) : IMealVisionProvider
{
    public string ProviderName => "Mock";
    public async Task<MealVisionProviderResult> AnalyseAsync(MealVisionProviderRequest request, CancellationToken ct) { var o = options.Value.Mock; if (o.DelayMilliseconds > 0) await Task.Delay(o.DelayMilliseconds, ct); if (o.ForceTimeout || request.Scenario == "ProviderTimeout") throw new MealVisionTimeoutException("The meal-vision provider timed out."); if (o.ForceProviderFailure || request.Scenario == "ProviderFailure") throw new MealVisionProviderException("The meal-vision provider failed."); if (o.ForceMalformedResponse || request.Scenario == "MalformedResponse") return Result(true, [Item("", 2, -1, -5, "Cup")]); return (request.Scenario ?? o.Scenario) switch { "NoFood" => Result(false, []), "PoorImageQuality" => Result(true, [Item("unclear food", .4m, .2m, null, "Unknown")], false), "DuplicateItems" => Result(true, [Item("steamed rice", .9m, .7m, 150, "Cup"), Item("steamed rice", .88m, .68m, 150, "Cup")]), "AmbiguousFishCurry" => Result(true, [Item("fish curry", .55m, .5m, 180, "Katori", [new("rohu fish curry", .45m), new("hilsa curry", .35m)])]), _ => BengaliLunch() }; }
    private static MealVisionProviderResult BengaliLunch() => new(true, "Bengali lunch", SuggestedMealType.Lunch, new(true, .91m, []), [Item("cooked white rice", .94m, .67m, 190, "Cup", regional: "bhaat"), Item("masoor dal", .91m, .7m, 180, "Katori", regional: "musur dal"), Item("rohu fish curry", .88m, .58m, 170, "Katori", regional: "rui macher jhol")], [new(2, "Was extra oil added?", "Added fat can affect nutrition matching.", ClarificationImpact.High)], "mock-v1", "mock-request");
    private static ProviderMealItem Item(string name, decimal recognition, decimal portion, decimal? grams, string unit, IReadOnlyList<AlternativeCandidate>? alternatives = null, string? regional = null) => new(name, regional, null, name.Contains("curry", StringComparison.OrdinalIgnoreCase) ? "Curried" : "Boiled", 1, unit, grams, recognition, portion, alternatives ?? [], [], name.Contains("curry", StringComparison.OrdinalIgnoreCase) ? ["cooking oil"] : []);
    private static MealVisionProviderResult Result(bool food, IReadOnlyList<ProviderMealItem> items, bool acceptable = true) => new(food, food ? "Mock meal" : null, SuggestedMealType.Unknown, new(acceptable, acceptable ? .9m : .3m, acceptable ? [] : [ImageQualityIssue.Blurry]), items, [], "mock-v1", "mock-request");
}
public sealed class MealVisionProviderCatalog(IOptions<MealVisionOptions> options) : IMealVisionProviderCatalog
{
    public IReadOnlyList<MealVisionProviderCapability> GetCapabilities()
    {
        var o = options.Value;
        return [
            Capability("Mock", "Mock scenarios", false, true, null, ["BengaliLunch", "NoFood", "PoorImageQuality", "AmbiguousFishCurry"], o.Mock.Scenario),
            Capability("OpenAi", "OpenAI", false, o.OpenAi.Enabled && !string.IsNullOrWhiteSpace(o.OpenAi.ApiKey), o.OpenAi.Enabled ? "Configure the server API key." : "Disabled by server configuration.", [o.OpenAi.Model], o.OpenAi.Model),
            Capability("Gemini", "Google Gemini", false, IsConfigured(o.Gemini), "Configure and enable Gemini on the server.", Models(o.Gemini), o.Gemini.Model),
            Capability("Anthropic", "Anthropic Claude", false, IsConfigured(o.Anthropic), "Configure and enable Claude on the server.", Models(o.Anthropic), o.Anthropic.Model),
            Capability("Ollama", "Ollama local", true, o.Ollama.Enabled && Uri.TryCreate(o.Ollama.Endpoint, UriKind.Absolute, out _), "Start Ollama or configure its local endpoint.", Models(o.Ollama), o.Ollama.Model),
            Capability("OpenAiCompatible", "OpenAI-compatible", false, IsConfigured(o.OpenAiCompatible), "Configure and enable a server-managed compatible endpoint.", Models(o.OpenAiCompatible), o.OpenAiCompatible.Model)
        ];
    }
    public MealVisionProviderCapability Resolve(string? providerId, string? modelId)
    {
        var selected = string.IsNullOrWhiteSpace(providerId) ? options.Value.Provider.ToString() : providerId;
        var provider = GetCapabilities().SingleOrDefault(x => string.Equals(x.Id, selected, StringComparison.OrdinalIgnoreCase));
        if (provider is null || !provider.IsAvailable) throw new MealVisionProviderException("The selected meal-analysis provider is unavailable.", ProviderFailureType.Configuration);
        if (!string.IsNullOrWhiteSpace(modelId) && !provider.Models.Any(x => string.Equals(x.Id, modelId, StringComparison.Ordinal))) throw new MealVisionProviderException("The selected meal-analysis model is not allowed.", ProviderFailureType.Configuration);
        return provider;
    }
    private static bool IsConfigured(ConfiguredMealVisionOptions x) => x.Enabled && !string.IsNullOrWhiteSpace(x.ApiKey) && Uri.TryCreate(x.Endpoint, UriKind.Absolute, out _) && !string.IsNullOrWhiteSpace(x.Model);
    private static List<string> Models(ConfiguredMealVisionOptions x) => x.AllowedModels.Count == 0 ? [x.Model] : x.AllowedModels;
    private static MealVisionProviderCapability Capability(string id, string label, bool local, bool available, string? missing, IReadOnlyList<string> models, string current) => new(id, label, local, available, available ? null : missing, models.Where(x => !string.IsNullOrWhiteSpace(x)).Distinct(StringComparer.OrdinalIgnoreCase).Select(x => new MealVisionModelCapability(x, x, string.Equals(x, current, StringComparison.OrdinalIgnoreCase))).ToList());
}
public sealed class MealVisionProviderResolver(IEnumerable<IMealVisionProvider> providers, IMealVisionProviderCatalog catalog) : IMealVisionProviderResolver
{
    public IMealVisionProvider Resolve(string? providerId = null, string? modelId = null)
    {
        var name = catalog.Resolve(providerId, modelId).Id;
        return providers.SingleOrDefault(x => string.Equals(x.ProviderName, name, StringComparison.OrdinalIgnoreCase))
            ?? throw new MealVisionProviderException($"Meal-vision provider {name} is not registered.", ProviderFailureType.Configuration);
    }
}
public sealed class MealVisionAnalysisService(IMealVisionProviderResolver resolver, IMealVisionPromptBuilder promptBuilder, IMealVisionResponseValidator validator, IFoodNameNormalizer normalizer, IOptions<MealVisionOptions> options, ILogger<MealVisionAnalysisService> logger) : IMealVisionAnalysisService
{
    private static readonly Action<ILogger, string, int, Exception?> Started = LoggerMessage.Define<string, int>(LogLevel.Information, new(2001, "MealVisionAnalysisStarted"), "MealVisionAnalysisStarted {CorrelationId} {ImageByteLength}");
    private static readonly Action<ILogger, string, string, long, Exception?> Completed = LoggerMessage.Define<string, string, long>(LogLevel.Information, new(2002, "MealVisionAnalysisCompleted"), "MealVisionAnalysisCompleted {CorrelationId} {Status} {DurationMs}");
    public async Task<MealVisionAnalysisResult> AnalyseAsync(MealVisionAnalysisInput input, CancellationToken ct) { var o = options.Value; MealVisionImageValidator.Validate(input, o.MaximumImageBytes); var id = string.IsNullOrWhiteSpace(input.ClientCorrelationId) ? Guid.NewGuid().ToString("N") : input.ClientCorrelationId[..Math.Min(input.ClientCorrelationId.Length, 100)]; Started(logger, id, input.ImageBytes.Length, null); var prompt = promptBuilder.Build(new(input.Locale, input.CuisineHints, input.DietPreference, input.MealContext)); var provider = resolver.Resolve(input.ProviderId, input.ModelId); var sw = Stopwatch.StartNew(); using var timeout = CancellationTokenSource.CreateLinkedTokenSource(ct); timeout.CancelAfter(TimeSpan.FromSeconds(o.RequestTimeoutSeconds)); MealVisionProviderResult raw; try { raw = await provider.AnalyseAsync(new(input.ImageBytes, input.MimeType, prompt, input.Locale, input.CuisineHints, input.DietPreference, o.MaximumItems, input.MockScenario, input.ModelId), timeout.Token); } catch (OperationCanceledException) when (!ct.IsCancellationRequested) { throw new MealVisionTimeoutException("The meal-vision provider timed out."); } var validation = validator.Validate(raw, o.MaximumItems); if (!validation.IsValid) throw new MealVisionSchemaValidationException(string.Join(" ", validation.Errors)); var warnings = new List<string>(); var seen = new HashSet<string>(StringComparer.Ordinal); var items = raw.Items.Select(x => Normalize(x, o, seen, warnings)).ToList(); var status = !raw.ImageQuality.Acceptable ? AnalysisStatus.Rejected : warnings.Count > 0 || items.Any(x => x.RequiresConfirmation) ? AnalysisStatus.SucceededWithWarnings : AnalysisStatus.Succeeded; sw.Stop(); Completed(logger, id, status.ToString(), sw.ElapsedMilliseconds, null); return new(id, status, provider.ProviderName, raw.Model, prompt.PromptVersion, prompt.SchemaVersion, raw.ContainsFood, raw.MealName?.Trim(), raw.MealTypeSuggestion, raw.ImageQuality, items, o.EnableClarificationQuestions ? raw.ClarificationQuestions.DistinctBy(x => x.Question).ToList() : [], warnings, sw.ElapsedMilliseconds, raw.ProviderRequestId, DateTime.UtcNow); }
    private MealVisionItem Normalize(ProviderMealItem x, MealVisionOptions o, HashSet<string> seen, List<string> global) { var name = x.DetectedName.Trim(); var normalized = normalizer.Normalize(name); var itemWarnings = new List<string>(); if (!seen.Add(normalized)) { var warning = $"Possible duplicate item detected: {name}."; itemWarnings.Add(warning); global.Add(warning); } _ = Enum.TryParse<PreparationMethod>(x.PreparationMethod, true, out var method); if (!Enum.TryParse<EstimatedServingUnit>(x.EstimatedUnit, true, out var unit)) unit = EstimatedServingUnit.Unknown; var alternatives = x.Alternatives.Where(a => !string.Equals(normalizer.Normalize(a.Name), normalized, StringComparison.Ordinal)).DistinctBy(a => normalizer.Normalize(a.Name)).Take(5).ToList(); var hidden = x.PossibleHiddenIngredients.Select(Clean).Where(s => s.Length > 0).Distinct(StringComparer.OrdinalIgnoreCase).ToList(); var requires = x.RecognitionConfidence < o.MinimumRecognitionConfidence || x.PortionConfidence < o.MinimumPortionConfidence || x.EstimatedGrams is null || unit == EstimatedServingUnit.Unknown || method == PreparationMethod.Unknown || alternatives.Any(a => a.Confidence >= .3m) || hidden.Count > 0 || itemWarnings.Count > 0; return new(name, Clean(x.RegionalName), method, x.EstimatedQuantity, unit, x.EstimatedGrams, decimal.Round(x.RecognitionConfidence, 3), decimal.Round(x.PortionConfidence, 3), o.EnableAlternativeCandidates ? alternatives : [], x.VisibleIngredients.Select(Clean).Where(s => s.Length > 0).Distinct(StringComparer.OrdinalIgnoreCase).ToList(), hidden, requires, itemWarnings); }
    private static string Clean(string? value) => new string((value ?? string.Empty).Where(c => !char.IsControl(c)).ToArray()).Trim();
}


