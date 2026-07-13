using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using NutritionTracker.Domain.Authentication;
using NutritionTracker.Infrastructure.Persistence;

namespace NutritionTracker.Api.Authentication;

public sealed class AuthenticationOptions
{
    public const string SectionName = "Authentication";
    public string Issuer { get; set; } = "NutriLens";
    public string Audience { get; set; } = "NutriLens.Mobile";
    public string SigningKey { get; set; } = string.Empty;
    public int AccessTokenMinutes { get; set; } = 15;
    public int RefreshTokenDays { get; set; } = 30;
    public bool AllowRegistration { get; set; } = true;
}

public interface ICurrentUser
{
    bool IsAuthenticated { get; }
    string? UserId { get; }
    string RequireUserId();
}

public sealed class CurrentUser(IHttpContextAccessor accessor) : ICurrentUser
{
    public bool IsAuthenticated => accessor.HttpContext?.User.Identity?.IsAuthenticated == true;
    public string? UserId => accessor.HttpContext?.User.FindFirstValue(JwtRegisteredClaimNames.Sub)
        ?? accessor.HttpContext?.User.FindFirstValue(ClaimTypes.NameIdentifier);
    public string RequireUserId() => UserId ?? throw new BadHttpRequestException("Authentication is required.", StatusCodes.Status401Unauthorized);
}

public sealed record TokenPair(string AccessToken, string RefreshToken, DateTime AccessTokenExpiresAtUtc);

public sealed class TokenService(IOptions<AuthenticationOptions> options, NutritionTrackerDbContext db)
{
    private readonly AuthenticationOptions _options = options.Value;

    public async Task<TokenPair> IssueAsync(ApplicationUser user, CancellationToken ct)
    {
        var now = DateTime.UtcNow;
        var expires = now.AddMinutes(_options.AccessTokenMinutes);
        var claims = new[] { new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()), new Claim(JwtRegisteredClaimNames.Email, user.Email), new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()) };
        var credentials = new SigningCredentials(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.SigningKey)), SecurityAlgorithms.HmacSha256);
        var jwt = new JwtSecurityToken(_options.Issuer, _options.Audience, claims, now, expires, credentials);
        var rawRefresh = Convert.ToBase64String(RandomNumberGenerator.GetBytes(48));
        db.RefreshTokens.Add(new RefreshToken { UserId = user.Id, TokenHash = Hash(rawRefresh), ExpiresAtUtc = now.AddDays(_options.RefreshTokenDays) });
        await db.SaveChangesAsync(ct);
        return new TokenPair(new JwtSecurityTokenHandler().WriteToken(jwt), rawRefresh, expires);
    }

    public async Task<TokenPair?> RotateAsync(string rawToken, CancellationToken ct)
    {
        var hash = Hash(rawToken);
        var token = await db.RefreshTokens.Include(x => x.User).SingleOrDefaultAsync(x => x.TokenHash == hash, ct);
        if (token is null || token.RevokedAtUtc is not null || token.ExpiresAtUtc <= DateTime.UtcNow || !token.User.IsActive) return null;
        token.RevokedAtUtc = DateTime.UtcNow;
        var pair = await IssueAsync(token.User, ct);
        token.ReplacedByHash = Hash(pair.RefreshToken);
        await db.SaveChangesAsync(ct);
        return pair;
    }

    public async Task RevokeAsync(string rawToken, CancellationToken ct)
    {
        var token = await db.RefreshTokens.SingleOrDefaultAsync(x => x.TokenHash == Hash(rawToken), ct);
        if (token is not null && token.RevokedAtUtc is null) { token.RevokedAtUtc = DateTime.UtcNow; await db.SaveChangesAsync(ct); }
    }

    private static string Hash(string value) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value))).ToLowerInvariant();
}

public sealed class UserIdentityMiddleware(RequestDelegate next, IWebHostEnvironment environment)
{
    public async Task InvokeAsync(HttpContext context)
    {
        if (context.User.Identity?.IsAuthenticated == true)
        {
            var id = context.User.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? context.User.FindFirstValue(ClaimTypes.NameIdentifier);
            context.Request.Headers["X-Development-User-Id"] = id;
        }
        else if (!environment.IsDevelopment() && !environment.IsEnvironment("Testing"))
        {
            context.Request.Headers.Remove("X-Development-User-Id");
        }

        if (context.Request.Path.StartsWithSegments("/api") && !context.Request.Path.StartsWithSegments("/api/auth") &&
            context.User.Identity?.IsAuthenticated != true && !(environment.IsDevelopment() || environment.IsEnvironment("Testing")))
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsJsonAsync(new Microsoft.AspNetCore.Mvc.ProblemDetails { Status = 401, Title = "Authentication is required." });
            return;
        }
        await next(context);
    }
}
