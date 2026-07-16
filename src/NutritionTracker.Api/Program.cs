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
using NutritionTracker.Api.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;
using NutritionTracker.Domain.Authentication;
using System.Text;
using System.Threading.RateLimiting;
using NutritionTracker.Api.Privacy;
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
builder.Services.AddDataProtection();
builder.Services.AddInfrastructure(builder.Configuration);
var authenticationOptions = builder.Configuration.GetSection(AuthenticationOptions.SectionName).Get<AuthenticationOptions>() ?? new AuthenticationOptions();
if (builder.Environment.IsProduction())
{
    if (authenticationOptions.SigningKey.Length < 32 || authenticationOptions.SigningKey.Contains("change-me", StringComparison.OrdinalIgnoreCase))
        throw new InvalidOperationException("Production Authentication:SigningKey must be a secret of at least 32 characters.");
    if (!builder.Configuration.GetValue<bool>("Production:RequireHttps"))
        throw new InvalidOperationException("Production requires HTTPS.");
    if (builder.Configuration["MealAnalysis:Provider"] is null)
        throw new InvalidOperationException("Production requires an explicit meal-image storage provider.");
    if (string.Equals(builder.Configuration["MealAnalysis:Provider"], "Local", StringComparison.OrdinalIgnoreCase) && !builder.Configuration.GetValue<bool>("MealAnalysis:AllowLocalInProduction"))
        throw new InvalidOperationException("Production Local image storage must be explicitly enabled for a protected self-hosted deployment.");
}
builder.Services.AddOptions<AuthenticationOptions>().BindConfiguration(AuthenticationOptions.SectionName).Validate(x => x.SigningKey.Length >= 32 && x.AccessTokenMinutes is >= 5 and <= 60 && x.RefreshTokenDays is >= 1 and <= 90, "Authentication configuration is invalid.").ValidateOnStart();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUser, CurrentUser>();
builder.Services.AddScoped<TokenService>();
builder.Services.AddScoped<IPasswordHasher<ApplicationUser>, PasswordHasher<ApplicationUser>>();
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(options =>
{
    options.MapInboundClaims = false;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidIssuer = authenticationOptions.Issuer,
        ValidateAudience = true,
        ValidAudience = authenticationOptions.Audience,
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(authenticationOptions.SigningKey)),
        ValidateLifetime = true,
        ClockSkew = TimeSpan.FromSeconds(30),
        NameClaimType = "sub"
    };
});
builder.Services.AddAuthorization();
builder.Services.AddRateLimiter(options => options.AddPolicy("authentication", context => RateLimitPartition.GetFixedWindowLimiter(context.Connection.RemoteIpAddress?.ToString() ?? "unknown", _ => new FixedWindowRateLimiterOptions { PermitLimit = 10, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 })));

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
    await FoodSeedSynchronization.Gate.WaitAsync();
    try
    {
        await using var scope = app.Services.CreateAsyncScope();
        await FoodDevelopmentSeeder.SeedAsync(scope.ServiceProvider);
        await BengaliFoodSeeder.SeedAsync(scope.ServiceProvider);
        await NutritionFoundationSeeder.SeedAsync(scope.ServiceProvider);
    }
    finally { FoodSeedSynchronization.Gate.Release(); }
}

app.UseGlobalExceptionHandling();
app.UseSerilogRequestLogging();
app.UseRateLimiter();

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
app.UseAuthentication();
app.UseMiddleware<UserIdentityMiddleware>();
app.UseAuthorization();

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
app.MapFastingEndpoints();
app.MapAuthenticationEndpoints();
app.MapPrivacyEndpoints();
app.MapMealVisionStatusEndpoints();
if (app.Environment.IsDevelopment() || app.Environment.IsEnvironment("Testing"))
{
    app.MapMealVisionDevelopmentEndpoints();
    app.MapMealVisionCapabilitiesEndpoints();
}

app.Run();

public partial class Program;
internal static class FoodSeedSynchronization { internal static SemaphoreSlim Gate { get; } = new(1, 1); }
