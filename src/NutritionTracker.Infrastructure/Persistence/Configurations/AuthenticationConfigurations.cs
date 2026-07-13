using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using NutritionTracker.Domain.Authentication;

namespace NutritionTracker.Infrastructure.Persistence.Configurations;

public sealed class ApplicationUserConfiguration : IEntityTypeConfiguration<ApplicationUser>
{
    public void Configure(EntityTypeBuilder<ApplicationUser> builder)
    {
        var b = builder;
        b.ToTable("application_users"); b.HasKey(x => x.Id);
        b.Property(x => x.Email).HasMaxLength(320).IsRequired();
        b.Property(x => x.NormalizedEmail).HasMaxLength(320).IsRequired();
        b.Property(x => x.PasswordHash).HasMaxLength(1000).IsRequired();
        b.HasIndex(x => x.NormalizedEmail).IsUnique();
    }
}

public sealed class RefreshTokenConfiguration : IEntityTypeConfiguration<RefreshToken>
{
    public void Configure(EntityTypeBuilder<RefreshToken> builder)
    {
        var b = builder;
        b.ToTable("refresh_tokens"); b.HasKey(x => x.Id);
        b.Property(x => x.TokenHash).HasMaxLength(64).IsRequired();
        b.Property(x => x.ReplacedByHash).HasMaxLength(64);
        b.HasIndex(x => x.TokenHash).IsUnique();
        b.HasIndex(x => new { x.UserId, x.ExpiresAtUtc });
        b.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}

public sealed class IdempotencyRecordConfiguration : IEntityTypeConfiguration<IdempotencyRecord>
{
    public void Configure(EntityTypeBuilder<IdempotencyRecord> builder)
    {
        var b = builder;
        b.ToTable("idempotency_records"); b.HasKey(x => x.Id);
        b.Property(x => x.UserId).HasMaxLength(128).IsRequired(); b.Property(x => x.Key).HasMaxLength(128).IsRequired();
        b.Property(x => x.Operation).HasMaxLength(128).IsRequired(); b.Property(x => x.ResponseJson).HasColumnType("jsonb");
        b.HasIndex(x => new { x.UserId, x.Key, x.Operation }).IsUnique();
    }
}
