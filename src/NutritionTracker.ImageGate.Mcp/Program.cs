using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace NutritionTracker.ImageGate.Mcp;

public partial class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);
        builder.Services.AddOptions<ImageGateOptions>()
            .BindConfiguration(ImageGateOptions.SectionName)
            .Validate(x => Uri.TryCreate(x.Ollama.Endpoint, UriKind.Absolute, out _) && !string.IsNullOrWhiteSpace(x.Ollama.Model) && x.MaximumImageBytes is >= 1024 and <= 20_000_000 && x.RequestTimeoutSeconds is >= 1 and <= 120, "ImageGate configuration is invalid.")
            .ValidateOnStart();
        builder.Services.AddHttpClient<OllamaImageGateModel>((serviceProvider, client) =>
        {
            var options = serviceProvider.GetRequiredService<Microsoft.Extensions.Options.IOptions<ImageGateOptions>>().Value;
            client.BaseAddress = new Uri(options.Ollama.Endpoint, UriKind.Absolute);
            client.Timeout = Timeout.InfiniteTimeSpan;
        });
        builder.Services.AddSingleton<IImageGateModel, OllamaImageGateModel>();
        builder.Services.AddTransient<ImageGateTools>();
        builder.Services.AddHealthChecks().AddCheck("image-gate", () => HealthCheckResult.Healthy(), tags: ["live", "ready"]);
        builder.Services.AddMcpServer()
            .WithHttpTransport(options => options.Stateless = true)
            .WithTools<ImageGateTools>();

        var app = builder.Build();
        app.MapHealthChecks("/health");
        app.MapMcp("/mcp");
        app.Run();
    }
}
