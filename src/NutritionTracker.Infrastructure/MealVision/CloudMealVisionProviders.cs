using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Options;
using NutritionTracker.Application.MealVision;

namespace NutritionTracker.Infrastructure.MealVision;

internal static class StructuredMealResult
{
    internal static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);
    internal static MealVisionProviderResult Parse(string? content, string model, string? requestId, string provider)
    {
        if (string.IsNullOrWhiteSpace(content)) throw new MealVisionProviderException($"{provider} returned no structured meal analysis.", ProviderFailureType.MalformedResponse);
        try { return (JsonSerializer.Deserialize<OpenAiMealResult>(content, Json) ?? throw new JsonException()).ToProviderResult(model, requestId); }
        catch (JsonException) { throw new MealVisionProviderException($"{provider} returned an invalid structured meal analysis.", ProviderFailureType.MalformedResponse); }
    }
    internal static MealVisionProviderException Failure(string provider, HttpStatusCode status) => status switch
    {
        HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden => new($"{provider} authentication failed.", ProviderFailureType.Authentication),
        (HttpStatusCode)429 => new($"{provider} rate limit reached.", ProviderFailureType.RateLimited),
        _ => new($"{provider} meal analysis is unavailable.", ProviderFailureType.Network)
    };
}

public sealed class GeminiMealVisionProvider(HttpClient client, IOptions<MealVisionOptions> options) : IMealVisionProvider
{
    public string ProviderName => "Gemini";
    public async Task<MealVisionProviderResult> AnalyseAsync(MealVisionProviderRequest request, CancellationToken ct)
    {
        var o = options.Value.Gemini; if (!o.Enabled || string.IsNullOrWhiteSpace(o.ApiKey)) throw new MealVisionProviderException("Gemini meal vision is not configured.", ProviderFailureType.Configuration);
        var model = request.ModelId ?? o.Model;
        var body = new { systemInstruction = new { parts = new[] { new { text = request.Prompt.SystemPrompt } } }, contents = new[] { new { role = "user", parts = new object[] { new { text = request.Prompt.UserPrompt }, new { inlineData = new { mimeType = request.MimeType, data = Convert.ToBase64String(request.ImageBytes) } } } } }, generationConfig = new { responseMimeType = "application/json", responseJsonSchema = OpenAiMealSchema.Value, temperature = 0 } };
        using var response = await client.PostAsJsonAsync($"models/{model}:generateContent?key={Uri.EscapeDataString(o.ApiKey)}", body, StructuredMealResult.Json, ct);
        if (!response.IsSuccessStatusCode) throw StructuredMealResult.Failure("Gemini", response.StatusCode);
        using var doc = await JsonDocument.ParseAsync(await response.Content.ReadAsStreamAsync(ct), cancellationToken: ct);
        var text = doc.RootElement.GetProperty("candidates")[0].GetProperty("content").GetProperty("parts")[0].GetProperty("text").GetString();
        return StructuredMealResult.Parse(text, model, null, "Gemini");
    }
}

public sealed class AnthropicMealVisionProvider(HttpClient client, IOptions<MealVisionOptions> options) : IMealVisionProvider
{
    public string ProviderName => "Anthropic";
    public async Task<MealVisionProviderResult> AnalyseAsync(MealVisionProviderRequest request, CancellationToken ct)
    {
        var o = options.Value.Anthropic; if (!o.Enabled || string.IsNullOrWhiteSpace(o.ApiKey)) throw new MealVisionProviderException("Claude meal vision is not configured.", ProviderFailureType.Configuration);
        var model = request.ModelId ?? o.Model;
        using var message = new HttpRequestMessage(HttpMethod.Post, "v1/messages");
        message.Headers.Add("x-api-key", o.ApiKey); message.Headers.Add("anthropic-version", "2023-06-01");
        message.Content = JsonContent.Create(new
        {
            model,
            max_tokens = o.MaxOutputTokens,
            system = request.Prompt.SystemPrompt,
            messages = new[] { new { role = "user", content = new object[]
            {
                new { type = "image", source = new { type = "base64", media_type = request.MimeType, data = Convert.ToBase64String(request.ImageBytes) } },
                new { type = "text", text = request.Prompt.UserPrompt + " Return only JSON matching the supplied meal-analysis contract." }
            } } }
        });
        using var response = await client.SendAsync(message, ct); if (!response.IsSuccessStatusCode) throw StructuredMealResult.Failure("Claude", response.StatusCode);
        using var doc = await JsonDocument.ParseAsync(await response.Content.ReadAsStreamAsync(ct), cancellationToken: ct);
        var text = doc.RootElement.GetProperty("content")[0].GetProperty("text").GetString();
        return StructuredMealResult.Parse(text, model, doc.RootElement.TryGetProperty("id", out var id) ? id.GetString() : null, "Claude");
    }
}

public sealed class OpenAiCompatibleMealVisionProvider(HttpClient client, IOptions<MealVisionOptions> options) : IMealVisionProvider
{
    public string ProviderName => "OpenAiCompatible";
    public async Task<MealVisionProviderResult> AnalyseAsync(MealVisionProviderRequest request, CancellationToken ct)
    {
        var o = options.Value.OpenAiCompatible; if (!o.Enabled || string.IsNullOrWhiteSpace(o.ApiKey)) throw new MealVisionProviderException("The compatible meal-vision endpoint is not configured.", ProviderFailureType.Configuration);
        var model = request.ModelId ?? o.Model;
        using var message = new HttpRequestMessage(HttpMethod.Post, "v1/chat/completions"); message.Headers.Authorization = new AuthenticationHeaderValue("Bearer", o.ApiKey);
        message.Content = JsonContent.Create(new
        {
            model,
            response_format = new { type = "json_object" },
            messages = new object[]
            {
                new { role = "system", content = request.Prompt.SystemPrompt },
                new { role = "user", content = new object[]
                {
                    new { type = "text", text = request.Prompt.UserPrompt },
                    new { type = "image_url", image_url = new { url = $"data:{request.MimeType};base64,{Convert.ToBase64String(request.ImageBytes)}" } }
                } }
            }
        });
        using var response = await client.SendAsync(message, ct); if (!response.IsSuccessStatusCode) throw StructuredMealResult.Failure("Compatible provider", response.StatusCode);
        using var doc = await JsonDocument.ParseAsync(await response.Content.ReadAsStreamAsync(ct), cancellationToken: ct);
        var text = doc.RootElement.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString();
        return StructuredMealResult.Parse(text, model, doc.RootElement.TryGetProperty("id", out var id) ? id.GetString() : null, "Compatible provider");
    }
}
