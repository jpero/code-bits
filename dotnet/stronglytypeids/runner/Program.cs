using corelib;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

var serviceProvider = new ServiceCollection()
    .AddDbContext<MyDbContext>(options =>
        options.UseSqlServer("Server=.;Database=stronglytypeids;User Id=sa;Password=P@ssword1;encrypt=false;"), 
        ServiceLifetime.Transient
    )
    .BuildServiceProvider();

using (var context1 = serviceProvider.GetRequiredService<MyDbContext>())
{
    context1.Database.EnsureDeleted();
    context1.Database.EnsureCreated();
    Console.WriteLine("Database initialized.");

    var persons = new[] {
        new Person { PersonID = new PersonID(11), Name = "John Doe", SignUpDate = DateTime.Now },
        new Person { PersonID = new PersonID(22), Name = "Jane Doe", SignUpDate = DateTime.Now }

    };

    context1.AddRange(persons);
    context1.SaveChanges();

}

using (var context2 = serviceProvider.GetRequiredService<MyDbContext>())
{
    var personID = new PersonID(22);
    context2.Person.Where(p => p.PersonID == personID).ToList().ForEach(p => Console.WriteLine(p.Name));
}