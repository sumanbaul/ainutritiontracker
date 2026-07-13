using Microsoft.EntityFrameworkCore;
using NutritionTracker.Domain.Profiles;
using NutritionTracker.Infrastructure.Persistence;

namespace NutritionTracker.Api.Nutrition;

public sealed record StartFastRequest(int TargetDurationMinutes, DateTime? StartedAtUtc, string? ClientIdempotencyKey);
public sealed record FinishFastRequest(DateTime? EndedAtUtc, string? ClientIdempotencyKey, long? ExpectedVersion);

public static class FastingEndpoints
{
    private const int MinimumMinutes = 60;
    private const int MaximumMinutes = 72 * 60;
    public static IEndpointRouteBuilder MapFastingEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/fasting");
        group.MapPost("/start", Start);
        group.MapGet("/active", Active);
        group.MapGet("/history", History);
        group.MapPost("/{id:guid}/end", End);
        group.MapPost("/{id:guid}/cancel", Cancel);
        return routes;
    }

    private static string User(HttpContext context) => context.Request.Headers.TryGetValue("X-Development-User-Id", out var user) && !string.IsNullOrWhiteSpace(user) ? user.ToString() : throw new BadHttpRequestException("X-Development-User-Id is required.", 401);
    private static IQueryable<ActiveFast> Owned(NutritionTrackerDbContext db, string user) => db.ActiveFasts.Where(x => x.UserId == user);

    private static async Task<IResult> Start(HttpContext context, NutritionTrackerDbContext db, StartFastRequest request, CancellationToken ct)
    {
        var user = User(context);
        if (request.TargetDurationMinutes is < MinimumMinutes or > MaximumMinutes) return Results.ValidationProblem(new Dictionary<string, string[]> { ["targetDurationMinutes"] = [$"Select a target between {MinimumMinutes / 60} and {MaximumMinutes / 60} hours."] });
        var now = DateTime.UtcNow;
        var start = request.StartedAtUtc?.ToUniversalTime() ?? now;
        if (start > now.AddMinutes(5)) return Results.ValidationProblem(new Dictionary<string, string[]> { ["startedAtUtc"] = ["The start time cannot be materially in the future."] });
        var existing = await Owned(db, user).OrderByDescending(x => x.UpdatedAtUtc).FirstOrDefaultAsync(x => x.Status == ActiveFastStatus.Active || (!string.IsNullOrWhiteSpace(request.ClientIdempotencyKey) && x.StartOperationId == request.ClientIdempotencyKey), ct);
        if (existing is not null) return existing.Status == ActiveFastStatus.Active ? Results.Ok(View(existing, now)) : Results.Conflict(new { Detail = "This start operation was already completed." });
        var fast = new ActiveFast { UserId = user, StartedAtUtc = start, TargetDurationMinutes = request.TargetDurationMinutes, PlannedEndAtUtc = start.AddMinutes(request.TargetDurationMinutes), StartOperationId = request.ClientIdempotencyKey };
        db.ActiveFasts.Add(fast); await db.SaveChangesAsync(ct); return Results.Created($"/api/fasting/{fast.Id}", View(fast, now));
    }

    private static async Task<IResult> Active(HttpContext context, NutritionTrackerDbContext db, CancellationToken ct)
    {
        var fast = await Owned(db, User(context)).AsNoTracking().SingleOrDefaultAsync(x => x.Status == ActiveFastStatus.Active, ct);
        return fast is null ? Results.NoContent() : Results.Ok(View(fast, DateTime.UtcNow));
    }

    private static async Task<IResult> History(HttpContext context, NutritionTrackerDbContext db, int? take, CancellationToken ct)
    {
        var user = User(context); var count = Math.Clamp(take ?? 20, 1, 100);
        var completed = await db.FastingWindows.AsNoTracking().Where(x => x.UserId == user && x.EndedAtUtc != null).OrderByDescending(x => x.EndedAtUtc).Take(count).Select(x => new { x.Id, x.StartedAtUtc, x.EndedAtUtc }).ToListAsync(ct);
        var cancelled = await Owned(db, user).AsNoTracking().Where(x => x.Status == ActiveFastStatus.Cancelled).OrderByDescending(x => x.UpdatedAtUtc).Take(count).Select(x => new { x.Id, x.StartedAtUtc, EndedAtUtc = (DateTime?)null, x.TargetDurationMinutes }).ToListAsync(ct);
        var result = completed.Select(x => new { x.Id, Status = "Completed", x.StartedAtUtc, x.EndedAtUtc, TargetDurationMinutes = (int?)null, DurationMinutes = (int)(x.EndedAtUtc!.Value - x.StartedAtUtc).TotalMinutes })
            .Concat(cancelled.Select(x => new { x.Id, Status = "Cancelled", x.StartedAtUtc, x.EndedAtUtc, TargetDurationMinutes = (int?)x.TargetDurationMinutes, DurationMinutes = 0 }))
            .OrderByDescending(x => x.EndedAtUtc ?? x.StartedAtUtc).Take(count);
        return Results.Ok(result);
    }

    private static async Task<IResult> End(HttpContext context, NutritionTrackerDbContext db, Guid id, FinishFastRequest request, CancellationToken ct)
    {
        var user = User(context); var fast = await Owned(db, user).SingleOrDefaultAsync(x => x.Id == id, ct); if (fast is null) return Results.NotFound();
        if (fast.Status == ActiveFastStatus.Completed) return Results.Ok(View(fast, DateTime.UtcNow));
        if (fast.Status != ActiveFastStatus.Active) return Results.Conflict(new { Detail = "This fast is no longer active." });
        if (request.ExpectedVersion is not null && request.ExpectedVersion != fast.Version) return Results.Problem(statusCode: 409, title: "The fast changed on another device.", extensions: new Dictionary<string, object?> { ["serverVersion"] = fast.Version });
        var end = request.EndedAtUtc?.ToUniversalTime() ?? DateTime.UtcNow; if (end <= fast.StartedAtUtc) return Results.ValidationProblem(new Dictionary<string, string[]> { ["endedAtUtc"] = ["The end time must be after the start time."] });
        if (!string.IsNullOrWhiteSpace(request.ClientIdempotencyKey) && await db.FastingWindows.AnyAsync(x => x.UserId == user && x.ClientOperationId == request.ClientIdempotencyKey, ct)) { fast.Status = ActiveFastStatus.Completed; await db.SaveChangesAsync(ct); return Results.Ok(View(fast, end)); }
        var completed = new FastingWindow { UserId = user, StartedAtUtc = fast.StartedAtUtc, EndedAtUtc = end, ClientOperationId = request.ClientIdempotencyKey }; db.FastingWindows.Add(completed); fast.Status = ActiveFastStatus.Completed; fast.EndOperationId = request.ClientIdempotencyKey; fast.CompletedFastingWindowId = completed.Id; await db.SaveChangesAsync(ct); return Results.Ok(View(fast, end));
    }

    private static async Task<IResult> Cancel(HttpContext context, NutritionTrackerDbContext db, Guid id, FinishFastRequest request, CancellationToken ct)
    {
        var fast = await Owned(db, User(context)).SingleOrDefaultAsync(x => x.Id == id, ct); if (fast is null) return Results.NotFound(); if (fast.Status == ActiveFastStatus.Cancelled) return Results.Ok(View(fast, DateTime.UtcNow)); if (fast.Status != ActiveFastStatus.Active) return Results.Conflict(new { Detail = "A completed fast cannot be cancelled." }); if (request.ExpectedVersion is not null && request.ExpectedVersion != fast.Version) return Results.Problem(statusCode: 409, title: "The fast changed on another device."); fast.Status = ActiveFastStatus.Cancelled; await db.SaveChangesAsync(ct); return Results.Ok(View(fast, DateTime.UtcNow));
    }

    private static object View(ActiveFast fast, DateTime now) { var elapsed = now > fast.StartedAtUtc ? now - fast.StartedAtUtc : TimeSpan.Zero; var target = TimeSpan.FromMinutes(fast.TargetDurationMinutes); var remaining = target > elapsed ? target - elapsed : TimeSpan.Zero; return new { fast.Id, Status = fast.Status.ToString(), fast.StartedAtUtc, fast.TargetDurationMinutes, fast.PlannedEndAtUtc, fast.Version, ElapsedSeconds = (long)elapsed.TotalSeconds, ProgressFraction = Math.Min(1m, (decimal)elapsed.TotalMinutes / fast.TargetDurationMinutes), RemainingSeconds = (long)remaining.TotalSeconds, IsTargetReached = elapsed >= target, fast.CompletedFastingWindowId }; }
}
