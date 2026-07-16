using NutritionTracker.Domain.Foods;
namespace NutritionTracker.Application.MealVision;

public enum MealVisionProviderKind { Mock, OpenAi, Gemini, Anthropic, Ollama, OpenAiCompatible }
public enum SuggestedMealType { Breakfast, Lunch, Dinner, Snack, Beverage, Unknown }
public enum ImageQualityIssue { TooDark, TooBright, Blurry, FoodPartiallyVisible, MultipleMeals, Obstructed, TooFar, TooClose, NonFoodImage, UnsupportedImage, Unknown }
public enum ClarificationImpact { Low, Medium, High }
public enum EstimatedServingUnit { Gram, Millilitre, Teaspoon, Tablespoon, Cup, Katori, Bowl, Ladle, Plate, Piece, Slice, Roti, Chapati, Paratha, Serving, Unknown }
public enum AnalysisStatus { Succeeded, SucceededWithWarnings, Rejected, Failed }
public enum ProviderFailureType { Configuration, Authentication, RateLimited, Timeout, Network, MalformedResponse, SchemaValidation, ContentRejected, UnsupportedImage, Unknown }
public enum ImagePreflightDecision { Accepted, Rejected, Uncertain }

public sealed record MealVisionAnalysisInput(byte[] ImageBytes, string MimeType, string? FileName, int? ImageWidth, int? ImageHeight, string Locale, IReadOnlyList<string> PreferredLanguages, IReadOnlyList<string> CuisineHints, string? DietPreference, string? MealContext, string? ClientCorrelationId, string? MockScenario, string? ProviderId = null, string? ModelId = null);
public sealed record MealVisionPrompt(string SystemPrompt, string UserPrompt, string PromptVersion, string SchemaVersion);
public sealed record MealVisionPromptContext(string Locale, IReadOnlyList<string> CuisineHints, string? DietPreference, string? MealContext);
public sealed record MealVisionProviderRequest(byte[] ImageBytes, string MimeType, MealVisionPrompt Prompt, string Locale, IReadOnlyList<string> CuisineHints, string? DietPreference, int MaximumItems, string? Scenario, string? ModelId = null);
public sealed record AlternativeCandidate(string Name, decimal Confidence);
public sealed record ProviderImageQuality(bool Acceptable, decimal Score, IReadOnlyList<ImageQualityIssue> Issues);
public sealed record ProviderMealItem(string DetectedName, string? RegionalName, string? CategoryHint, string? PreparationMethod, decimal? EstimatedQuantity, string? EstimatedUnit, decimal? EstimatedGrams, decimal RecognitionConfidence, decimal PortionConfidence, IReadOnlyList<AlternativeCandidate> Alternatives, IReadOnlyList<string> VisibleIngredients, IReadOnlyList<string> PossibleHiddenIngredients);
public sealed record ClarificationQuestion(int ItemIndex, string Question, string Reason, ClarificationImpact Impact);
public sealed record MealVisionProviderResult(bool ContainsFood, string? MealName, SuggestedMealType MealTypeSuggestion, ProviderImageQuality ImageQuality, IReadOnlyList<ProviderMealItem> Items, IReadOnlyList<ClarificationQuestion> ClarificationQuestions, string? Model = null, string? ProviderRequestId = null, string? RawResponse = null);
public sealed record MealVisionItem(string DetectedName, string? RegionalName, PreparationMethod PreparationMethod, decimal? EstimatedQuantity, EstimatedServingUnit EstimatedServingUnit, decimal? EstimatedGrams, decimal RecognitionConfidence, decimal PortionConfidence, IReadOnlyList<AlternativeCandidate> Alternatives, IReadOnlyList<string> VisibleIngredients, IReadOnlyList<string> PossibleHiddenIngredients, bool RequiresConfirmation, IReadOnlyList<string> Warnings);
public sealed record MealVisionAnalysisResult(string AnalysisId, AnalysisStatus Status, string Provider, string? Model, string PromptVersion, string SchemaVersion, bool ContainsFood, string? MealName, SuggestedMealType SuggestedMealType, ProviderImageQuality ImageQuality, IReadOnlyList<MealVisionItem> Items, IReadOnlyList<ClarificationQuestion> ClarificationQuestions, IReadOnlyList<string> Warnings, long ProcessingDurationMs, string? ProviderRequestId, DateTime CreatedAtUtc);
public sealed record MealVisionValidationResult(bool IsValid, IReadOnlyList<string> Errors);
public sealed record ImagePreflightResult(ImagePreflightDecision Decision, decimal FoodConfidence, decimal QualityScore, bool QualityAcceptable, IReadOnlyList<string> Issues, string DetectorVersion, long ProcessingDurationMs);

public interface IMealVisionProvider { string ProviderName { get; } Task<MealVisionProviderResult> AnalyseAsync(MealVisionProviderRequest request, CancellationToken ct); }
public sealed record MealVisionModelCapability(string Id, string DisplayName, bool IsDefault);
public sealed record MealVisionProviderCapability(string Id, string DisplayName, bool IsLocal, bool IsAvailable, string? UnavailableReason, IReadOnlyList<MealVisionModelCapability> Models);
public interface IMealVisionProviderCatalog { IReadOnlyList<MealVisionProviderCapability> GetCapabilities(); MealVisionProviderCapability Resolve(string? providerId, string? modelId); }
public interface IMealVisionProviderResolver { IMealVisionProvider Resolve(string? providerId = null, string? modelId = null); }
public interface IMealVisionAnalysisService { Task<MealVisionAnalysisResult> AnalyseAsync(MealVisionAnalysisInput input, CancellationToken ct); }
public interface IMealVisionPromptBuilder { MealVisionPrompt Build(MealVisionPromptContext context); }
public interface IMealVisionResponseValidator { MealVisionValidationResult Validate(MealVisionProviderResult r, int max); }
public interface IImagePreflightDetector { Task<ImagePreflightResult> DetectAsync(byte[] imageBytes, string mimeType, CancellationToken cancellationToken); }

public class MealVisionException(string message, ProviderFailureType failureType) : Exception(message) { public ProviderFailureType FailureType { get; } = failureType; }
public sealed class MealVisionImageValidationException(string message, int statusCode = 400) : MealVisionException(message, ProviderFailureType.UnsupportedImage) { public int StatusCode { get; } = statusCode; }
public sealed class MealVisionTimeoutException(string message) : MealVisionException(message, ProviderFailureType.Timeout);
public sealed class MealVisionProviderException(string message, ProviderFailureType failureType = ProviderFailureType.Unknown) : MealVisionException(message, failureType);
public sealed class MealVisionSchemaValidationException(string message) : MealVisionException(message, ProviderFailureType.SchemaValidation);
public sealed class MealVisionPreflightRejectedException(string message, IReadOnlyList<string> issues) : MealVisionException(message, ProviderFailureType.ContentRejected) { public IReadOnlyList<string> Issues { get; } = issues; }
public sealed class MealVisionPreflightUnavailableException(string message, Exception? innerException = null) : MealVisionException(message, ProviderFailureType.Network) { public Exception? InnerExceptionValue { get; } = innerException; }
