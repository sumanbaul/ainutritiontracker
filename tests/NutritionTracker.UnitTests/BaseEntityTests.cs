using FluentAssertions;
using NutritionTracker.Domain.Common;
using Xunit;

namespace NutritionTracker.UnitTests;

public sealed class BaseEntityTests
{
    [Fact]
    public void NewEntityHasANonEmptyIdentifier()
    {
        var entity = new TestEntity();

        entity.Id.Should().NotBeEmpty();
    }

    private sealed class TestEntity : BaseEntity;
}
