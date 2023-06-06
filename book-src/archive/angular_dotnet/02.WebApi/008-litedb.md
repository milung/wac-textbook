## Základná logika a persistencia údajov web služby

1. Pridajte závislosť na knižnicu [LiteDB](https://www.litedb.org/). Otvorte nové
  okno príkazového riadku, prejdite do priečinku `ambulance-api` a vykonajte príkaz

    ```powershell
    dotnet add package litedb
    ```

    >info:> Zapúzdrená NoSQL databáza _LiteDB_ je vhodná len pre malé projekty
    > s niekoľkými používateľmi a relatívne malým množstvom údajov. Pre reálne projekty
    > budú vhodnejšie alternatívne riešenia so zodpovedajúcimi kvalitatívnymi parametrami.
    > Funkčne je táto databáza podobná ostatným NoSQL databázam, takže poznatky získané
    > pri jej používaní sa dajú ľahko aplikovať aj v ostatných riešeniach.

2. Vytvorte nový priečinok `Services` a v ňom súbor `Services\IDataRepository.cs`
  s nasledujúcim obsahom:

    ```csharp
    using eu.incloud.ambulance.Models;

    namespace eu.incloud.ambulance.Services
    {
        /// <summary>
        /// Abstraction of the data repository keeping data model persistent
        ///
        /// Responsibilities:
        ///     * CRUD operations over data maodel
        ///     * Searching and filtering durring data retrieval
        /// </summary>
        public interface IDataRepository
        {
            /// <summary>
            /// Provides details about specific ambulance
            /// </summary>
            /// <param name="ambulanceId">id of the ambulance</param>
            /// <returns>ambulance details</returns>
            Ambulance GetAmbulanceData(string ambulanceId);

            /// <summary>
            /// Updates or inserts details about specific/new ambulance
            /// </summary>
            /// <param name="ambulance">ambulance data</param>
            /// <returns>ambulance instance with correct id, if inserting</returns>
            Ambulance UpsertAmbulanceData(Ambulance ambulance);

            /// <summary>
            /// Deletes details about specific ambulance
            /// </summary>
            /// <param name="ambulanceId">id of the ambulance</param>
            void DeleteAmbulance(string ambulanceId);
        }
    }
    ```

3. V priečinku `Services` vytvorte súbor `Services\DataRepository.cs`
  s nasledujúcim obsahom:

    ```csharp
    using System.IO;
    using eu.incloud.ambulance.Models;
    using LiteDB;
    using Microsoft.AspNetCore.Hosting;
    using Microsoft.Extensions.Configuration;

    namespace eu.incloud.ambulance.Services
    {
        class DataRepository : IDataRepository
        {
            private readonly LiteDatabase liteDb;
            private static readonly string AMBULANCES_COLLECTION = "ambulances";

            public DataRepository(
                IWebHostEnvironment environment, IConfiguration configuration)
            {
                string dbPath = configuration["DATA_REPOSITORY_DB"];
                if (dbPath == null || dbPath.Length == 0)
                {
                    dbPath = Path.Combine(
                        environment.ContentRootPath, "data-repository.litedb");
                }
                this.liteDb = new LiteDatabase(dbPath);
            }

            public Ambulance GetAmbulanceData(string ambulanceId)
            {
                var collection = this.liteDb.GetCollection<Ambulance>(AMBULANCES_COLLECTION);
                return collection.FindById(ambulanceId);
            }

            public Ambulance UpsertAmbulanceData(Ambulance ambulance)
            {
                var collection = this.liteDb.GetCollection<Ambulance>(AMBULANCES_COLLECTION);
                var existing = collection.FindById(ambulance.Id);
                if (existing == null)
                {
                    var idValue = collection.Insert(ambulance);
                    ambulance.Id = idValue.AsString;
                }
                else
                {
                    collection.Update(ambulance);
                }
                return ambulance;
            }

            public void DeleteAmbulance(string ambulanceId)
            {
                var collection = this.liteDb.GetCollection<Ambulance>(AMBULANCES_COLLECTION);
                collection.Delete(ambulanceId);
            }
        }
    }
    ```

4. Vytvorte nový priečinok `Extensions` a v ňom súbor `Extensions\DataRepositoryDI.cs`
  s nasledujúcim obsahom:

    ```csharp
    using eu.incloud.ambulance.Services;

    namespace Microsoft.Extensions.DependencyInjection
    {
        static class DataRepositoryDI
        {
            /// supportive extension function for dependency
            /// injection of the service
            public static IServiceCollection AddDataRepository(
                this IServiceCollection services)
                => services.AddSingleton<IDataRepository, DataRepository>();
        }
    }
    ```

    Ďalej upravte súbor `Startup.cs` a doplňte novo vytvorenú službu

    ```csharp
    public void ConfigureServices(IServiceCollection services)
    {
        ...
        services.AddDataRepository();
        ...
    }
    ```

5. Upravte funkcionalitu v súbore `Controllers\DevelopersApi.cs` tak, aby využívala
  persistenciu dát. Hlavičky metód nie sú nižšie uvádzané, zostávaju ale bez zmeny.

    ```csharp
    ...
    using System.Linq;
    using eu.incloud.ambulance.Services;

    namespace eu.incloud.ambulance.Controllers
    {
        /// <summary/>
        public class DevelopersApiController : ControllerBase
        {
            private readonly IDataRepository repository;

            /// <summary/>
            public DevelopersApiController(IDataRepository repository)
                => this.repository = repository;

            ...
            public virtual IActionResult DeleteWaitingListEntry(
                [FromRoute][Required] string ambulanceId,
                [FromRoute][Required] string entryId)
            {
                var ambulance = this.repository.GetAmbulanceData(ambulanceId);
                var entry = ambulance == null ? null
                    : ambulance.WaitingList.FirstOrDefault(_ => _.Id.Equals(entryId));

                if (entry == null) { return new NotFoundResult(); }

                ambulance.WaitingList.Remove(entry);
                this.repository.UpsertAmbulanceData(ambulance);

                return new OkResult();
            }

            ...
            public virtual ActionResult<Ambulance> GetAmbulanceDetails(
                [FromRoute][Required] string ambulanceId)
            {
                var ambulance = this.repository.GetAmbulanceData(ambulanceId);
                if (ambulance == null) { return new NotFoundResult(); }
                else { return ambulance; }
            }

            ...
            public virtual ActionResult<Condition> GetCondition(
                [FromRoute][Required] string ambulanceId,
                [FromRoute][Required] string conditionCode)
            {
                var ambulance = this.repository.GetAmbulanceData(ambulanceId);
                var condition = ambulance == null ? null
                    : ambulance.PredefinedConditions.FirstOrDefault(
                        _ => _.Code.Equals(conditionCode));

                if (condition == null) { return new NotFoundResult(); }
                else { return condition; }
            }

            ...
            public virtual ActionResult<IEnumerable<Condition>> GetConditions(
                [FromRoute][Required] string ambulanceId)
            {
                var ambulance = this.repository.GetAmbulanceData(ambulanceId);
                if (ambulance == null) { return new NotFoundResult(); }

                return ambulance.PredefinedConditions;
            }
            ...
            public virtual ActionResult<IEnumerable<WaitingListEntry>> GetWaitingListEntries(
                [FromRoute][Required] string ambulanceId)
            {
                var ambulance = this.repository.GetAmbulanceData(ambulanceId);
                if (ambulance == null) { return new NotFoundResult(); }

                return ambulance.WaitingList;
            }
            ...
            public virtual ActionResult<WaitingListEntry> GetWaitingListEntry(
                [FromRoute][Required] string ambulanceId,
                [FromRoute][Required] string entryId)
            {
                var ambulance = this.repository.GetAmbulanceData(ambulanceId);
                var entry = ambulance == null ? null
                    : ambulance.WaitingList.FirstOrDefault(_ => _.Id.Equals(entryId));

                if (entry == null) { return new NotFoundResult(); }
                else { return entry; }
            }
            ...
            public virtual ActionResult<WaitingListEntry> StoreWaitingListEntry(
                [FromRoute][Required] string ambulanceId,
                [FromBody] WaitingListEntry body)
            {
                var ambulance = this.repository.GetAmbulanceData(ambulanceId);
                if (ambulance == null) { return new NotFoundResult(); }

                body.Id = Guid.NewGuid().ToString();
                ambulance.WaitingList.Add(body);
                this.repository.UpsertAmbulanceData(ambulance);

                return body;
            }

            ...
            public virtual IActionResult UpdateCondition(
                [FromRoute][Required] string ambulanceId,
                [FromRoute][Required] string conditionCode,
                [FromBody] Condition body)
            {
                if (!conditionCode.Equals(body.Code))
                {
                    return new BadRequestResult();
                }

                var ambulance = this.repository.GetAmbulanceData(ambulanceId);
                var condition = ambulance == null ? null
                    : ambulance.PredefinedConditions.FirstOrDefault(
                        _ => _.Code.Equals(conditionCode));

                if (condition == null) { return new NotFoundResult(); }

                ambulance.PredefinedConditions.Remove(condition);
                ambulance.PredefinedConditions.Add(body);

                this.repository.UpsertAmbulanceData(ambulance);
                return new OkResult();
            }

            ...
            public virtual ActionResult<WaitingListEntry> UpdateWaitingListEntry(
                [FromRoute][Required] string ambulanceId,
                [FromRoute][Required] string entryId,
                [FromBody] WaitingListEntry body)
            {
                if (!entryId.Equals(body.Id)) { return new BadRequestResult(); }

                var ambulance = this.repository.GetAmbulanceData(ambulanceId);
                var entry = ambulance == null ? null
                    : ambulance.WaitingList.FirstOrDefault(_ => _.Id.Equals(entryId));

                if (entry == null) { return new NotFoundResult(); }

                ambulance.WaitingList.Remove(entry);
                ambulance.WaitingList.Add(body);

                this.repository.UpsertAmbulanceData(ambulance);
                return body;
            }
        }
    }
    ```

    Podobným spôsobom upravte súbor `Controllers\AdminsApi.cs`

    ```csharp
    ...
    using System.Linq;
    using eu.incloud.ambulance.Services;

    namespace eu.incloud.ambulance.Controllers
    {
        /// <summary/>
        public class AdminsApiController : ControllerBase
        {
            private readonly IDataRepository repository;

            /// <summary/>
            public AdminsApiController(IDataRepository repository)
                => this.repository = repository;

            ...
            public virtual IActionResult CreateAmbulanceDetails(
                [FromRoute][Required] string ambulanceId,
                [FromBody] Ambulance body)
            {
                var ambulance = this.repository.GetAmbulanceData(ambulanceId);
                if (ambulance != null) { return new BadRequestResult(); }
                this.repository.UpsertAmbulanceData(body);
                return new OkResult();
            }

            ...
            public virtual IActionResult DeleteCondition(
                [FromRoute][Required] string ambulanceId,
                [FromRoute][Required] string conditionCode)
            {
                var ambulance = this.repository.GetAmbulanceData(ambulanceId);
                var condition = ambulance == null ? null
                    : ambulance.PredefinedConditions.FirstOrDefault(
                        _ => _.Code.Equals(conditionCode));

                if (condition == null) { return new NotFoundResult(); }

                ambulance.PredefinedConditions.Remove(condition);
                this.repository.UpsertAmbulanceData(ambulance);

                return new OkResult();
            }

            ...
            public virtual IActionResult StoreCondition(
                [FromRoute][Required] string ambulanceId,
                [FromBody] Condition body)
            {
                var ambulance = this.repository.GetAmbulanceData(ambulanceId);
                if (ambulance == null) { return new NotFoundResult(); }

                ambulance.PredefinedConditions.Add(body);
                this.repository.UpsertAmbulanceData(ambulance);

                return new OkResult();
            }
        }
    }
    ```

>warning:> Naša implementácia metód v kontroleroch nezodpovedá
> popisu v hlavičkách. Popis metód (ich API) sa musí zhodovať s tým, čo metódy
> vracajú. Popisy obsahujú aj chybové návratové hodnoty, ktoré sme v kóde
> nenaprogramovali. Ošetrenie chybových stavov a vracanie zodpovedajúcich html
> kódov necháme na študentov.

V tomto stave je vaša webová služba schopná persistentne ukladať stav čakajúcich
pacientov.

Archivujte váš kód do vzdialeného repozitára.

V ďalšom kroku vyskúšame funkčnosť a pripravíme stav databázy s využitím
nástroja [Postman](https://www.getpostman.com/)
