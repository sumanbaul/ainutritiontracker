using FluentAssertions;
using Microsoft.Extensions.Options;
using NutritionTracker.Infrastructure.Meals;
using Xunit;

namespace NutritionTracker.UnitTests;

public sealed class MealImageStorageTests
{
    [Fact]
    public async Task RetainedImageCanBeReadAndDeletedWithinTheConfiguredRoot()
    {
        var root = Path.Combine(Path.GetTempPath(), $"nutrilens-image-test-{Guid.NewGuid():N}");
        try
        {
            var storage = new LocalMealImageStorage(Options.Create(new MealAnalysisOptions { LocalStorageRoot = root, RetainImages = true }));
            var key = await storage.SaveAsync(new byte[] { 0xFF, 0xD8, 0xFF }, "image/jpeg", "image-storage-test-user", Guid.NewGuid(), CancellationToken.None);

            (await storage.ReadAsync(key, CancellationToken.None)).Should().Equal(0xFF, 0xD8, 0xFF);
            await storage.DeleteAsync(key, CancellationToken.None);
            (await storage.ReadAsync(key, CancellationToken.None)).Should().BeNull();
        }
        finally
        {
            if (Directory.Exists(root)) Directory.Delete(root, true);
        }
    }

    [Fact]
    public async Task ReadHonoursRetentionAndRejectsTraversal()
    {
        var root = Path.Combine(Path.GetTempPath(), $"nutrilens-image-test-{Guid.NewGuid():N}");
        var storage = new LocalMealImageStorage(Options.Create(new MealAnalysisOptions { LocalStorageRoot = root, RetainImages = false }));

        (await storage.ReadAsync("2026/07/missing.jpg", CancellationToken.None)).Should().BeNull();
        var action = () => storage.DeleteAsync("../outside.jpg", CancellationToken.None);
        await action.Should().ThrowAsync<InvalidOperationException>();
    }
}
