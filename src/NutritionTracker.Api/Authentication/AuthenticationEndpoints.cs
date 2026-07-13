using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using NutritionTracker.Domain.Authentication;
using NutritionTracker.Infrastructure.Persistence;

namespace NutritionTracker.Api.Authentication;

public sealed record CredentialsRequest(string Email, string Password);
public sealed record RefreshRequest(string RefreshToken);

public static class AuthenticationEndpoints
{
    public static IEndpointRouteBuilder MapAuthenticationEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/auth").AllowAnonymous();
        group.MapPost("/register", Register).RequireRateLimiting("authentication");
        group.MapPost("/login", Login).RequireRateLimiting("authentication");
        group.MapPost("/refresh", Refresh).RequireRateLimiting("authentication");
        group.MapPost("/logout", Logout);
        return routes;
    }

    private static async Task<IResult> Register(CredentialsRequest request, NutritionTrackerDbContext db, IPasswordHasher<ApplicationUser> hasher, TokenService tokens, IOptions<AuthenticationOptions> options, CancellationToken ct)
    {
        if (!options.Value.AllowRegistration) return Results.NotFound();
        var email = Normalize(request.Email);
        if (email is null || request.Password.Length < 12) return Results.ValidationProblem(new Dictionary<string, string[]> { ["credentials"] = ["Use a valid email and a password of at least 12 characters."] });
        if (await db.ApplicationUsers.AnyAsync(x => x.NormalizedEmail == email, ct)) return Results.Conflict(new { title = "An account already exists." });
        var user = new ApplicationUser { Email = request.Email.Trim(), NormalizedEmail = email };
        user.PasswordHash = hasher.HashPassword(user, request.Password);
        db.ApplicationUsers.Add(user); await db.SaveChangesAsync(ct);
        return Results.Ok(await tokens.IssueAsync(user, ct));
    }

    private static async Task<IResult> Login(CredentialsRequest request, NutritionTrackerDbContext db, IPasswordHasher<ApplicationUser> hasher, TokenService tokens, CancellationToken ct)
    {
        var email = Normalize(request.Email);
        var user = email is null ? null : await db.ApplicationUsers.SingleOrDefaultAsync(x => x.NormalizedEmail == email && x.IsActive, ct);
        if (user is null || hasher.VerifyHashedPassword(user, user.PasswordHash, request.Password) == PasswordVerificationResult.Failed) return Results.Problem(statusCode: 401, title: "Invalid credentials.");
        return Results.Ok(await tokens.IssueAsync(user, ct));
    }

    private static async Task<IResult> Refresh(RefreshRequest request, TokenService tokens, CancellationToken ct) => await tokens.RotateAsync(request.RefreshToken, ct) is { } pair ? Results.Ok(pair) : Results.Problem(statusCode: 401, title: "The session has expired.");
    private static async Task<IResult> Logout(RefreshRequest request, TokenService tokens, CancellationToken ct) { await tokens.RevokeAsync(request.RefreshToken, ct); return Results.NoContent(); }
    private static string? Normalize(string value) { try { return new System.Net.Mail.MailAddress(value.Trim()).Address.ToUpperInvariant(); } catch { return null; } }
}
