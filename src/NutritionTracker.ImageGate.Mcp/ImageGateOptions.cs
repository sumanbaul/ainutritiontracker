namespace NutritionTracker.ImageGate.Mcp;

public sealed class ImageGateOptions
{
    public const string SectionName = "ImageGate";
    public int MaximumImageBytes { get; init; } = 5_000_000;
    public int RequestTimeoutSeconds { get; init; } = 20;
    public string DetectorVersion { get; init; } = "ollama-image-gate-v1";
    public OllamaImageGateOptions Ollama { get; init; } = new();
}

public sealed class OllamaImageGateOptions
{
    public string Endpoint { get; init; } = "http://127.0.0.1:11434/";
    public string Model { get; init; } = "gemma3:4b";
}
