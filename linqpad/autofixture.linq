<Query Kind="Program">
  <NuGetReference>AutoFixture.AutoMoq</NuGetReference>
  <Namespace>AutoFixture</Namespace>
  <Namespace>AutoFixture.AutoMoq</Namespace>
  <Namespace>Moq</Namespace>
</Query>

void Main()
{
	var fixture = new Fixture().Customize(new AutoMoqCustomization());
	
	var tripRepo = fixture.Create<StubRepo<Trip>>();
	
	var trips = tripRepo.Data;
	trips.Dump();
	
	var m_db = fixture.Freeze<Mock<IDatabase>>();
	
	m_db.Setup(d => d.GetRepo<Trip>()).Returns(tripRepo);
	//m_db.Setup(d => d.GetRepo<Stop>()).Returns((IRepo<Stop>)null);
	
	var service = fixture.Create<Service>();
	service.GetTrips().Dump();
	
	m_db.VerifyAll();
}

public class Service
{
	private IDatabase _db;
	public Service(IDatabase db) => _db = db;

	public List<Trip> GetTrips()
	{
		var trips = _db.GetRepo<Trip>().Query();
		var stopRepo = _db.GetRepo<Stop>();
		
		var query = from t in trips
			join s in stopRepo.Query() on t.ID equals s.TripID
			select t;
		
		return query.ToList();
	}
}

public interface IDatabase
{
	void SaveChanges();
	
	IRepo<T> GetRepo<T>() where T : class;
}

public interface IRepo<T> where T : class
{
	IQueryable<T> Query();
	
	T GetById(int id);
}

public class StubRepo<T> : IRepo<T> where T : class
{
	public List<T> Data { get; set; }
	
	public T GetById(int id)
	{
		return null;
	}

	public IQueryable<T> Query()
	{
		return Data?.AsQueryable();
	}
}

public class Trip
{
	public int ID { get; set; }
}

public class Stop
{
	public int TripID { get; set; }
}
