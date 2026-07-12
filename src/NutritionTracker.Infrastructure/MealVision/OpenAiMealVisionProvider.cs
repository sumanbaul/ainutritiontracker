using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Options;
using NutritionTracker.Application.MealVision;

namespace NutritionTracker.Infrastructure.MealVision;

/// <summary>Server-side OpenAI Responses API adapter. It never logs image bytes, responses, or credentials.</summary>
public sealed class OpenAiMealVisionProvider(HttpClient client, IOptions<MealVisionOptions> options) : IMealVisionProvider
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);
    public string ProviderName => "OpenAi";

    public async Task<MealVisionProviderResult> AnalyseAsync(MealVisionProviderRequest request, CancellationToken ct)
    {
        var configuration = options.Value.OpenAi;
        if (string.IsNullOrWhiteSpace(configuration.ApiKey))
            throw new MealVisionProviderException("OpenAI meal vision is not configured.", ProviderFailureType.Configuration);

        using var message = new HttpRequestMessage(HttpMethod.Post, "responses");
        message.Headers.Authorization = new AuthenticationHeaderValue("Bearer", configuration.ApiKey);
        message.Content = JsonContent.Create(CreateRequest(request, configuration));
        using var response = await client.SendAsync(message, HttpCompletionOption.ResponseHeadersRead, ct);
        if (!response.IsSuccessStatusCode)
            throw ProviderFailure(response.StatusCode);

        var document = await JsonDocument.ParseAsync(await response.Content.ReadAsStreamAsync(ct), cancellationToken: ct);
        using (document)
        {
            var root = document.RootElement;
            var output = ExtractOutputText(root);
            if (string.IsNullOrWhiteSpace(output))
                throw new MealVisionProviderException("OpenAI returned no structured meal analysis.", ProviderFailureType.MalformedResponse);
            try
            {
                var result = JsonSerializer.Deserialize<OpenAiMealResult>(output, Json)
                    ?? throw new JsonException("Structured result was empty.");
                return result.ToProviderResult(
                    root.TryGetProperty("model", out var model) ? model.GetString() : configuration.Model,
                    root.TryGetProperty("id", out var id) ? id.GetString() : null);
            }
            catch (JsonException)
            {
                throw new MealVisionProviderException("OpenAI returned an invalid structured meal analysis.", ProviderFailureType.MalformedResponse);
            }
        }
    }

    internal static object CreateRequest(MealVisionProviderRequest request, OpenAiMealVisionOptions options) => new
    {
        model = options.Model,
        instructions = request.Prompt.SystemPrompt,
        input = new[]
        {
            new
            {
                role = "user",
                content = new object[]
                {
                    new { type = "input_text", text = request.Prompt.UserPrompt },
                    new { type = "input_image", image_url = $"data:{request.MimeType};base64,{Convert.ToBase64String(request.ImageBytes)}", detail = options.ImageDetail }
                }
            }
        },
        max_output_tokens = options.MaxOutputTokens,
        text = new
        {
            format = new { type = "json_schema", name = "meal_vision", strict = true, schema = OpenAiMealSchema.Value }
        }
    };

    private static MealVisionProviderException ProviderFailure(HttpStatusCode status) => status switch
    {
        HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden => new("OpenAI authentication failed.", ProviderFailureType.Authentication),
        (HttpStatusCode)429 => new("OpenAI rate limit reached.", ProviderFailureType.RateLimited),
        _ => new("OpenAI meal analysis is unavailable.", ProviderFailureType.Network)
    };

    private static string? ExtractOutputText(JsonElement root)
    {
        if (root.TryGetProperty("output_text", out var outputText) && outputText.ValueKind == JsonValueKind.String)
            return outputText.GetString();
        if (!root.TryGetProperty("output", out var output) || output.ValueKind != JsonValueKind.Array) return null;
        foreach (var item in output.EnumerateArray())
        {
            if (!item.TryGetProperty("content", out var content) || content.ValueKind != JsonValueKind.Array) continue;
            foreach (var part in content.EnumerateArray())
                if (part.TryGetProperty("text", out var text) && text.ValueKind == JsonValueKind.String)
                    return text.GetString();
        }
        return null;
    }
}

internal sealed record OpenAiMealResult(bool ContainsFood, string? MealName, string MealTypeSuggestion, OpenAiImageQuality ImageQuality, IReadOnlyList<OpenAiMealItem> Items, IReadOnlyList<OpenAiClarificationQuestion> ClarificationQuestions)
{
    public MealVisionProviderResult ToProviderResult(string? model, string? requestId) => new(
        ContainsFood, MealName, Parse<SuggestedMealType>(MealTypeSuggestion),
        new(ImageQuality.Acceptable, ImageQuality.Score, ImageQuality.Issues.Select(Parse<ImageQualityIssue>).ToList()),
        Items.Select(x => new ProviderMealItem(x.DetectedName, x.RegionalName, x.CategoryHint, x.PreparationMethod, x.EstimatedQuantity, x.EstimatedUnit, x.EstimatedGrams, x.RecognitionConfidence, x.PortionConfidence, x.Alternatives.Select(a => new AlternativeCandidate(a.Name, a.Confidence)).ToList(), x.VisibleIngredients, x.PossibleHiddenIngredients)).ToList(),
        ClarificationQuestions.Select(x => new ClarificationQuestion(x.ItemIndex, x.Question, x.Reason, Parse<ClarificationImpact>(x.Impact))).ToList(), model, requestId);

    private static T Parse<T>(string value) where T : struct, Enum => Enum.TryParse<T>(value, true, out var parsed) ? parsed : default;
}
internal sealed record OpenAiImageQuality(bool Acceptable, decimal Score, IReadOnlyList<string> Issues);
internal sealed record OpenAiAlternative(string Name, decimal Confidence);
internal sealed record OpenAiMealItem(string DetectedName, string? RegionalName, string? CategoryHint, string? PreparationMethod, decimal? EstimatedQuantity, string? EstimatedUnit, decimal? EstimatedGrams, decimal RecognitionConfidence, decimal PortionConfidence, IReadOnlyList<OpenAiAlternative> Alternatives, IReadOnlyList<string> VisibleIngredients, IReadOnlyList<string> PossibleHiddenIngredients);
internal sealed record OpenAiClarificationQuestion(int ItemIndex, string Question, string Reason, string Impact);

internal static class OpenAiMealSchema
{
    public static readonly JsonElement Value = JsonDocument.Parse("""
    {"type":"object","additionalProperties":false,"required":["containsFood","mealName","mealTypeSuggestion","imageQuality","items","clarificationQuestions"],"properties":{"containsFood":{"type":"boolean"},"mealName":{"type":["string","null"]},"mealTypeSuggestion":{"type":"string","enum":["Breakfast","Lunch","Dinner","Snack","Beverage","Unknown"]},"imageQuality":{"type":"object","additionalProperties":false,"required":["acceptable","score","issues"],"properties":{"acceptable":{"type":"boolean"},"score":{"type":"number","minimum":0,"maximum":1},"issues":{"type":"array","items":{"type":"string","enum":["TooDark","TooBright","Blurry","FoodPartiallyVisible","MultipleMeals","Obstructed","TooFar","TooClose","NonFoodImage","UnsupportedImage","Unknown"]}}}},"items":{"type":"array","items":{"type":"object","additionalProperties":false,"required":["detectedName","regionalName","categoryHint","preparationMethod","estimatedQuantity","estimatedUnit","estimatedGrams","recognitionConfidence","portionConfidence","alternatives","visibleIngredients","possibleHiddenIngredients"],"properties":{"detectedName":{"type":"string"},"regionalName":{"type":["string","null"]},"categoryHint":{"type":["string","null"]},"preparationMethod":{"type":["string","null"]},"estimatedQuantity":{"type":["number","null"]},"estimatedUnit":{"type":["string","null"]},"estimatedGrams":{"type":["number","null"]},"recognitionConfidence":{"type":"number","minimum":0,"maximum":1},"portionConfidence":{"type":"number","minimum":0,"maximum":1},"alternatives":{"type":"array","items":{"type":"object","additionalProperties":false,"required":["name","confidence"],"properties":{"name":{"type":"string"},"confidence":{"type":"number","minimum":0,"maximum":1}}}},"visibleIngredients":{"type":"array","items":{"type":"string"}},"possibleHiddenIngredients":{"type":"array","items":{"type":"string"}}}}},"clarificationQuestions":{"type":"array","items":{"type":"object","additionalProperties":false,"required":["itemIndex","question","reason","impact"],"properties":{"itemIndex":{"type":"integer","minimum":0},"question":{"type":"string"},"reason":{"type":"string"},"impact":{"type":"string","enum":["Low","Medium","High"]}}}}}}
    """).RootElement.Clone();
}
