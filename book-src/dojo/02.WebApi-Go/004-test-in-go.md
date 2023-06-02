## Testovanie v jazyku Go

Testovanie je integrálnou súčasťou programovania s rovnakou dôležitosťou ako samotný zdrojový kód.

V jazyku [Go](https://go.dev/doc/tutorial/add-a-test) je zaintegrovaný jednoduchý framework na podporu testovania, ktorý pozostáva z príkazu [go test](https://pkg.go.dev/cmd/go#hdr-Test_packages) a balíka [testing](https://pkg.go.dev/testing).
Príkazom `go test` sa spustia všetky funkcie, ktoré spĺňajú nasledovné podmienky:

* Funkcia má signatúru `func (t *testing.T)`.
* Meno funkcie začína `Test` a pokračuje akýmkoľvek textom začínajúcim veľkým písmenom, napríklad `TestExample`.
* Názov súboru končí príponou `_test.go`, napríklad `api-admins_test.go`.

> _Poznámka_: Okrem funkcií začínajúcich na `Test` spúšťa `go test` príkaz aj [iné typy funkcií](https://pkg.go.dev/cmd/go#hdr-Testing_functions) a to takzvané `benchmark` a `example` funkcie.

Vzhľadom k tomu, že v rámci tohto kurzu kladieme dôraz na vysvetlenie detailov týkajúcich sa kontinuálneho dodávania aplikácie, testovanie web služby vynecháme, avšak, aby sme pre účely kontinuálnej integrácie mohli zaviesť krok zameraný na testovanie, vytvorte súbor `.../ambulance-webapi/router/router_test.go`. Pridajte nasledovný jednoduchý testovací kód.

```go
package router

import (
  "fmt"
  "testing"
)

func TestExample(t *testing.T) {
  if (false) {
    t.Fatalf("Failure!")
  }
  fmt.Printf("Test finished.")
}
```

Z priečinku `.../ambulance-webapi` vykonajte testy vo všetkých (pod)priečinkoch:

```bash
go test ./...
```

Archivujte váš kód do vzdialeného repozitára.
