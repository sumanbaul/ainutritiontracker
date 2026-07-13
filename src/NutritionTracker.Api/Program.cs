using FluentValidation;
using FluentValidation.AspNetCore;
using HealthChecks.NpgSql;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using NutritionTracker.Api.Configuration;
using NutritionTracker.Api.ExceptionHandling;
using NutritionTracker.Api.Profiles;
using NutritionTracker.Api.Foods;
using NutritionTracker.Api.MealVision;
using NutritionTracker.Api.Meals;
using NutritionTracker.Api.Nutrition;
using NutritionTracker.Infrastructure.MealVision;
using NutritionTracker.Application;
using NutritionTracker.Infrastructure;
using NutritionTracker.Infrastructure.Configuration;
using NutritionTracker.Infrastructure.Foods;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

var configuredMealVision = builder.Configuration.GetSection(MealVisionOptions.SectionName).Get<MealVisionOptions>() ?? new MealVisionOptions();
if (!builder.Environment.IsDevelopment() && !builder.Environment.IsEnvironment("Testing") && configuredMealVision.Provider == NutritionTracker.Application.MealVision.MealVisionProviderKind.Mock && !configuredMealVision.AllowMockInProduction)
{
    throw new InvalidOperationException("Mock meal vision is disabled outside Development and Testing.");
}

builder.Host.UseSerilog((context, services, configuration) => configuration
    .ReadFrom.Configuration(context.Configuration)
    .ReadFrom.Services(services)
    .Enrich.FromLogContext()
    .Enrich.WithProperty("Application", "NutritionTracker.Api"));

builder.Services.AddProblemDetails(options =>
{
    options.CustomizeProblemDetails = context => context.ProblemDetails.Extensions["traceId"] = context.HttpContext.TraceIdentifier;
});

builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);

builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssemblyContaining<Program>();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.ConfigureHttpJsonOptions(x => x.SerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter()));

var healthCheckOptions = builder.Configuration
    .GetSection(HealthReadinessOptions.SectionName)
    .Get<HealthReadinessOptions>() ?? new HealthReadinessOptions();
var connectionString = builder.Configuration.GetSection(DatabaseOptions.SectionName).GetValue<string>("DefaultConnection");

var healthChecks = builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy(), tags: ["live"]);

if (healthCheckOptions.EnableDatabaseReadinessCheck && connectionString is { Length: > 0 } configuredConnectionString)
{
    healthChecks.AddNpgSql(configuredConnectionString, name: "postgresql", tags: ["ready"]);
}

var app = builder.Build();

if (builder.Configuration.GetValue<bool>("FoodSeed:Enabled"))
{
    await using var scope = app.Services.CreateAsyncScope();
    await FoodDevelopmentSeeder.SeedAsync(scope.ServiceProvider);
    await BengaliFoodSeeder.SeedAsync(scope.ServiceProvider);
    await NutritionFoundationSeeder.SeedAsync(scope.ServiceProvider);
}

app.UseGlobalExceptionHandling();
app.UseSerilogRequestLogging();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Android development uses ADB reverse/LAN HTTP. Keep HTTPS mandatory outside Development.
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.MapHealthChecks("/health", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("live")
});

app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});
app.MapProfileEndpoints();
app.MapFoodEndpoints();
app.MapMealAnalysisEndpoints();
app.MapMealManagementEndpoints();
app.MapNutritionExpansionEndpoints();
if (app.Environment.IsDevelopment() || app.Environment.IsEnvironment("Testing"))
{
    app.MapMealVisionDevelopmentEndpoints();
    app.MapMealVisionCapabilitiesEndpoints();
}

app.Run();

public partial class Program;
