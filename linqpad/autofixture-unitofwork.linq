<Query Kind="Program">
  <NuGetReference>AutoFixture.AutoMoq</NuGetReference>
  <Namespace>AutoFixture</Namespace>
  <Namespace>AutoFixture.AutoMoq</Namespace>
  <Namespace>Moq</Namespace>
</Query>

void Main()
{
	var fixture = new Fixture();
	fixture.Customize(new AutoMoqCustomization());
	
	
	Mock<IRepo<Trip>> m_repo = fixture.Freeze<Mock<IRepo<Trip>>>();
	m_repo.Setup(m => m.Find(It.Is<int>(i => i == 123))).Returns (() => fixture.Create<Trip>());
	
	var m_uow = fixture.Freeze<Mock<IUnitOfWork>>();
	m_uow.Setup(m => m.Repository<Trip>()).Returns (() => m_repo.Object);

	var repo = m_uow.Object.Repository<Trip>();
	//if (repo == m_repo.Object) { Console.WriteLine("same repo"); }
	
	Trip t = repo.Find(123);
	
	t.Dump();
}

public static void SetupTripRepo(this IFixture f)
{
	
}

public interface IUnitOfWork
{
	IRepo<T> Repository<T>();
	
	int Commmit();
}

public interface IRepo<T>
{
	IQueryable<T> Query();
	
	T Find(params object[] ids);
}

public class Trip
{
	public string TripNumber { get; set; }
}

// You can define other methods, fields, classes and namespaces here