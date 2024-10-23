using StronglyTypedIds;

namespace corelib;

public class Person
{
    public PersonID PersonID { get; set; }
    public string Name { get; set; } = null!;        
    public DateTime SignUpDate { get; set; }
}

// [StronglyTypedId(Template.Int)]
// public readonly partial struct PersonID { };

public readonly record struct PersonID(int Value);