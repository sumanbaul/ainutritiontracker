using System.ComponentModel;
using System.Diagnostics;
using System.Text.Json;
using Microsoft.Extensions.Options;
using ModelContextProtocol.Server;

namespace NutritionTracker.ImageGate.Mcp;

public interface IImageGateModel
{
    Task<ImageGateClassification> ClassifyAsync(string imageBase64, string mimeType, CancellationToken cancellationToken);
}

public sealed record ImageGateClassification(bool IsFood, decimal FoodConfidence, decimal QualityScore, bool QualityAcceptable, IReadOnlyList<string> Issues);
public sealed record ImageGateToolResult(string Decision, decimal FoodConfidence, decimal QualityScore, bool QualityAcceptable, IReadOnlyList<string> Issues, string DetectorVersion, long ProcessingDurationMs);

[McpServerToolType]
public sealed class ImageGateTools(IImageGateModel model, IOptions<ImageGateOptions> options)
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);
    [McpServerTool(Name = "preflight_image", Idempotent = true), Description("Classifies a local meal image for food relevance and basic image quality before downstream meal analysis.")]
    public async Task<string> PreflightImageAsync(
        [Description("The image MIME type. Only image/jpeg, image/png, and image/webp are accepted.")] string mimeType,
        [Description("The image bytes encoded as base64. The server does not persist or log this value.")] string imageBase64,
        CancellationToken cancellationToken)
    {
        if (mimeType is not ("image/jpeg" or "image/png" or "image/webp")) throw new ArgumentException("Unsupported image MIME type.");
        byte[] bytes;
        try { bytes = Convert.FromBase64String(imageBase64); } catch (FormatException) { throw new ArgumentException("Image base64 is invalid."); }
        if (bytes.Length == 0 || bytes.Length > options.Value.MaximumImageBytes) throw new ArgumentException("Image is empty or exceeds the configured size limit.");
        if (!HasMatchingHeader(bytes, mimeType)) throw new ArgumentException("Image header does not match its MIME type.");
        var sw = Stopwatch.StartNew();
        var classification = await model.ClassifyAsync(imageBase64, mimeType, cancellationToken);
        sw.Stop();
        var issues = classification.Issues.Where(x => !string.IsNullOrWhiteSpace(x)).Distinct(StringComparer.OrdinalIgnoreCase).Take(20).ToArray();
        var decision = !classification.IsFood || !classification.QualityAcceptable || classification.FoodConfidence < .01m ? "Rejected" : classification.FoodConfidence < .80m || classification.QualityScore < .70m ? "Uncertain" : "Accepted";
        return JsonSerializer.Serialize(new ImageGateToolResult(decision, decimal.Round(classification.FoodConfidence, 3), decimal.Round(classification.QualityScore, 3), classification.QualityAcceptable, issues, options.Value.DetectorVersion, sw.ElapsedMilliseconds), Json);
    }

    private static bool HasMatchingHeader(byte[] bytes, string mimeType) => mimeType switch
    {
        "image/jpeg" => bytes.Length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8,
        "image/png" => bytes.Length > 7 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47,
        "image/webp" => bytes.Length > 11 && bytes[0] == (byte)'R' && bytes[1] == (byte)'I' && bytes[2] == (byte)'F' && bytes[3] == (byte)'F' && bytes[8] == (byte)'W' && bytes[9] == (byte)'E' && bytes[10] == (byte)'B' && bytes[11] == (byte)'P',
        _ => false
    };
}
