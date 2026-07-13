using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Options;
using NutritionTracker.Application.MealVision;

namespace NutritionTracker.Infrastructure.MealVision;

/// <summary>Local Ollama adapter. Images and prompts remain on the configured local server.</summary>
public sealed class OllamaMealVisionProvider(HttpClient client, IOptions<MealVisionOptions> options) : IMealVisionProvider
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);
    public string ProviderName => "Ollama";

    public async Task<MealVisionProviderResult> AnalyseAsync(MealVisionProviderRequest request, CancellationToken ct)
    {
        var config = options.Value.Ollama;
        if (!config.Enabled || !Uri.TryCreate(config.Endpoint, UriKind.Absolute, out _))
            throw new MealVisionProviderException("Ollama meal vision is not configured.", ProviderFailureType.Configuration);

        var body = new
        {
            model = request.ModelId ?? config.Model,
            stream = false,
            format = OpenAiMealSchema.Value,
            messages = new object[]
            {
                new { role = "system", content = request.Prompt.SystemPrompt },
                new { role = "user", content = request.Prompt.UserPrompt, images = new[] { Convert.ToBase64String(request.ImageBytes) } }
            },
            options = new { temperature = 0 }
        };
        using var response = await client.PostAsJsonAsync("api/chat", body, Json, ct);
        if (!response.IsSuccessStatusCode)
            throw Failure(response.StatusCode);
        using var document = await JsonDocument.ParseAsync(await response.Content.ReadAsStreamAsync(ct), cancellationToken: ct);
        var root = document.RootElement;
        var content = root.TryGetProperty("message", out var message) && message.TryGetProperty("content", out var value) ? value.GetString() : null;
        if (string.IsNullOrWhiteSpace(content)) throw new MealVisionProviderException("Ollama returned no structured meal analysis.", ProviderFailureType.MalformedResponse);
        try
        {
            var parsed = JsonSerializer.Deserialize<OpenAiMealResult>(content, Json) ?? throw new JsonException();
            return parsed.ToProviderResult(root.TryGetProperty("model", out var model) ? model.GetString() : request.ModelId ?? config.Model, null);
        }
        catch (JsonException)
        {
            throw new MealVisionProviderException("Ollama returned an invalid structured meal analysis.", ProviderFailureType.MalformedResponse);
        }
    }

    private static MealVisionProviderException Failure(HttpStatusCode status) => status switch
    {
        HttpStatusCode.NotFound => new("The selected Ollama model is not installed locally.", ProviderFailureType.Configuration),
        _ => new("Ollama is unavailable. Start Ollama and pull the selected model.", ProviderFailureType.Network)
    };
}
