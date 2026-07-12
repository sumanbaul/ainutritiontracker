using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace NutritionTracker.Api.ExceptionHandling;

public static class GlobalExceptionHandlerExtensions
{
    private static readonly Action<ILogger, string, string, Exception?> LogUnhandledException = LoggerMessage.Define<string, string>(
        LogLevel.Error,
        new EventId(1, nameof(LogUnhandledException)),
        "Unhandled exception for {RequestMethod} {RequestPath}");

    public static IApplicationBuilder UseGlobalExceptionHandling(this IApplicationBuilder app)
    {
        app.UseExceptionHandler(exceptionApp =>
        {
            exceptionApp.Run(async context =>
            {
                var exceptionFeature = context.Features.Get<IExceptionHandlerFeature>();
                var logger = context.RequestServices.GetRequiredService<ILoggerFactory>()
                    .CreateLogger("GlobalExceptionHandler");

                if (exceptionFeature?.Error is not null)
                {
                    LogUnhandledException(logger, context.Request.Method, context.Request.Path, exceptionFeature.Error);
                }

                var statusCode = exceptionFeature?.Error is BadHttpRequestException badRequest ? badRequest.StatusCode : StatusCodes.Status500InternalServerError;
                var problemDetails = new ProblemDetails
                {
                    Status = statusCode,
                    Title = statusCode == StatusCodes.Status500InternalServerError ? "An unexpected error occurred." : "The request is invalid.",
                    Type = $"https://httpstatuses.com/{statusCode}",
                    Instance = context.Request.Path
                };
                problemDetails.Extensions["traceId"] = context.TraceIdentifier;

                context.Response.StatusCode = problemDetails.Status.Value;
                context.Response.ContentType = "application/problem+json";
                await context.Response.WriteAsJsonAsync(problemDetails, cancellationToken: context.RequestAborted);
            });
        });

        return app;
    }
}
