using System;
using Microsoft.EntityFrameworkCore;

namespace corelib;

public class MyDbContext : DbContext
{
    public MyDbContext(DbContextOptions<MyDbContext> options) : base(options)
    {
    }

    public DbSet<Person> Person { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Person>(entity =>
            {
                entity.HasKey(e => e.PersonID);
                entity.Property(e => e.PersonID).HasConversion(
                    id => id.Value,
                    value => new PersonID(value)
                );
            });
        }
}
