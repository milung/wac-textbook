## Vytvorenie testovacej dllky

Vytvoríme si dllku, v ktorej budú unit testy pre naše web-api.

Otvorte okno s príkazovým riadkom a prejdite do priečinka `ambulance-webapi`, v ktorom je umiestnený projekt
`ambulance-api`. Vytvorte nový priečinok `ambulance-api.tests` a v ňom nový projekt typu _mstest_:

```powershell
mkdir ambulance-api.tests
cd ambulance-api.tests
dotnet new mstest -f net5.0
dotnet add reference ..\ambulance-api\ambulance-api.csproj
```

Výsledná štruktúra priečinkov:
- ambulance-spa
- ambulance-webapi
  - ambulance-api
  - ambulance-api.tests

Uistite sa, že v súbore `ambulance-api.tests.csproj` je špecifikovaná správna .NET verzia:

```html
...
<TargetFramework>net5.0</TargetFramework>
...
```

Nový projekt obsahuje jeden prázdny unit test.

Ak bol predtým v aplikácii _Visual Studio Code_ správne pridaný do Workspace nadradený adresár
ambulance-webapi, objaví sa nový adresár automaticky v našom pracovnom prostredí.

Urobte kópiu súboru `..\ambulance-api\.gitignore` do adresára `..\ambulance-api.tests\`.

Zbuildujte projekt a spustite test.

```powershell
dotnet restore
dotnet build
dotnet test
```

Test nič nerobí a preto je zelený. :-)

Archivujte váš kód do vzdialeného repozitára.
