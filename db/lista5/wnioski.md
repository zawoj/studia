# Wprowadzenie

kod źródłowy: https://github.com/zawoj/studia/tree/main/db/lista5

### Baza danych
Zbiór danych, który wybrałem, znajduje się w bazie danych Kaggle: 
https://www.kaggle.com/datasets/techmap/international-job-postings-september-2021

Jest to duża baza, ma dane geolokalizacyjne. Wystarczy dane jednego modelu rozdzielić na parę różnych modeli i będziemy mieć dobrą bazę reprezentatywną.

W pliku `types.ts` znajduje się 5 modeli.

Modele Kaggle:
- JobPostingBulk

Moje utworzone z głównego modelu:
- JobPositionModel
- OrganizationModel
- JobOfferModel
- LocationModel

W pliku `import-main.ts` znajdują się skrypty tworzące moje modele, które następnie będą wykorzystane do testów i dalszych zadań.

### Testy wydajności (z indeksami i bez)
### Dodane Indeksy

#### 1. Indeksy dla Organizations
- `name`: Przyspieszenie wyszukiwania po nazwie organizacji
- `source`: Filtrowanie organizacji według źródła
- `idInSource`: Szybkie wyszukiwanie po unikalnym identyfikatorze źródłowym
- `mergedID`: Łączenie rekordów organizacji
- `registryID`: Wyszukiwanie po oficjalnym numerze rejestracyjnym

#### 2. Indeksy dla JobPositions
- `organizationId`: Szybkie łączenie z organizacjami
- `name`: Wyszukiwanie pozycji po nazwie
- `locationId`: Szybkie pobieranie lokalizacji

#### 3. Indeksy dla JobOffers
- `positionId`: Łączenie z pozycjami pracy
- `organizationId`: Łączenie z organizacjami
- `dateCreated`: Sortowanie i filtrowanie po dacie utworzenia
- `dateExpired`: Filtrowanie ofert wygasłych
- `dateScraped`: Analiza dat zeskrobania ofert
- `idInSource`: Unikalne identyfikatory źródłowe
- `referenceID`: Wewnętrzne referencje
- `source`: Filtrowanie po źródle ofert

#### 4. Indeksy dla Locations
- `city`: Wyszukiwanie po mieście
- `country`: Filtrowanie po kraju
- `countryCode`: Szybkie wyszukiwanie krajów
- `state`: Filtrowanie po stanie/województwie
- `postCode`: Wyszukiwanie po kodzie pocztowym

#### 5. Specjalne Indeksy Geolokalizacyjne
- `geoPoint`: Indeks 2dsphere dla zapytań przestrzennych

#### 6. Indeksy Tekstowe
- Indeks tekstowy dla `jobOffers` obejmujący pola:
  - `text`
  - `html`
  - `contact.email`


Dla testów utworzyłem kilkanaście zapytań <TUTAJ KRÓTKI OGÓLNY OPIS>.
W pierwszym odpaleniu część odpowiedzialna za ustawianie indeksów została zakomentowana.

Rezultaty:
- Średni czas trwania zapytania
- Najdłuższy czas
- Najkrótszy czas

Każde zapytanie zostało wykonane 10 razy.

#### Wyniki
Wyniki znajdują się w dwóch plikach:
- `query_stats.json` dla zapytań bez indeksów
- `query_stats-index.json` dla zapytań z indeksami

### Tabela 1: Średni Czas Wykonania (AVG)

| Zapytanie | Przed Indeksami | Po Indeksach | Zmiana | Poprawa/Pogorszenie |
|-----------|-----------------|--------------|--------|---------------------|
| Geolokalizacja - Pobliskie Lokalizacje | 1051.55 ms | 1010.00 ms | -41.55 ms | 3.95% Poprawa |
| Wyszukiwanie Tekstowe - Wyniki | 46043.97 ms | 51704.92 ms | +5660.95 ms | 12.30% Pogorszenie |
| Analiza Wynagrodzeń wg Departamentów | 84976.98 ms | 80500.25 ms | -4476.73 ms | 5.27% Poprawa |
| Trendy Rekrutacyjne | 44393.62 ms | 2.12 ms | -44391.50 ms | 99.99% Poprawa |

### Tabela 2: Maksymalny Czas Wykonania (MAX)

| Zapytanie | Przed Indeksami | Po Indeksach | Zmiana | Poprawa/Pogorszenie |
|-----------|-----------------|--------------|--------|---------------------|
| Geolokalizacja - Pobliskie Lokalizacje | 1150.45 ms | 1158.23 ms | +7.78 ms | 0.68% Pogorszenie |
| Wyszukiwanie Tekstowe - Wyniki | 46806.55 ms | 67691.46 ms | +20884.91 ms | 44.63% Pogorszenie |
| Analiza Wynagrodzeń wg Departamentów | 87017.43 ms | 93459.65 ms | +6442.22 ms | 7.40% Pogorszenie |
| Trendy Rekrutacyjne | 46002.00 ms | 9.02 ms | -45992.98 ms | 99.98% Poprawa |

### Tabela 3: Minimalny Czas Wykonania (MIN)

| Zapytanie | Przed Indeksami | Po Indeksach | Zmiana | Poprawa/Pogorszenie |
|-----------|-----------------|--------------|--------|---------------------|
| Geolokalizacja - Pobliskie Lokalizacje | 1024.62 ms | 970.84 ms | -53.78 ms | 5.25% Poprawa |
| Wyszukiwanie Tekstowe - Wyniki | 45626.11 ms | 43433.07 ms | -2193.04 ms | 4.81% Poprawa |
| Analiza Wynagrodzeń wg Departamentów | 83619.68 ms | 76666.77 ms | -6952.91 ms | 8.32% Poprawa |
| Trendy Rekrutacyjne | 43342.16 ms | 0.84 ms | -43341.32 ms | 99.99% Poprawa |

Widać, że tam gdzie dodano indeksy, wyniki znacząco się poprawiły. Jednak tam gdzie ich nie dodałem, czas nieznacznie się pogorszył. Tutaj wysuwa się pytanie - czy dodanie indeksów do jednych pól/modeli może spowodować gorsze wyniki zapytań do innych? Otóż tak, jeśli źle przemyśli się modele i zastosowane indeksy. Należałoby zapewne jeszcze trochę podzielić modele, przemyśleć lepiej indeksy oraz przeanalizować dane.

### Transakcje i inne zaawansowane funkcjonalności MongoDB
Przykład użycia transakcji znajduje się w pliku `transaction.ts`.
Zaawansowane zapytania częściowo są w `main.ts` oraz bardziej pokazowo znajdują się w `query.ts`


# Wnioski
na podstawie zadania i doświadczenia mam następujące. Dokumentowe bazy danych mają kilka realnych zastosowań: gdy tworzymy MVP, gdy nasze dane trudno otypować oraz gdy filtrujemy geolokalizacyjnie. Każdy inny przypadek nie ma długotrwałych korzyści z wykorzystania dokumentowej bazy danych. Poniżej wyjaśniam, dlaczego te trzy rzeczy się do tego nadają.

### MVP
Gdy nie znamy jeszcze dokładnie potrzebnej struktury danych w projekcie bądź może się ona jeszcze często zmieniać.

### Trudne do otypowania dane
Miałem klienta, dla którego budowałem dedykowane rozwiązanie CMSowe (page builder). W takim przypadku dokumentowa baza danych sprawdza się idealnie, bo każda podstrona ma zupełnie inną strukturę. Prawdą też jest, że można takie rzeczy zaprogramować w relacyjnej bazie danych (WordPress), ale albo bardzo długo przemyślimy bazę danych, by mogła być dynamiczna, albo korzystamy z typów JSON. Tylko jaki jest sens zapisywania w JSON, skoro mamy cały "system" bazodanowy obsługujący ten rodzaj "plików".

### Filtracja Geolokalizacyjna
Oczywiście, że da się to zrobić rozsądnie w bazach relacyjnych. Ale trzeba tutaj oddać zasługi MongoDB, gdyż działa to bardzo dobrze, jest łatwe w wykorzystaniu dla programistów oraz spełnia założenia biznesowe w praktycznie każdym przypadku. Miałem już 3 projekty, gdy z tego powodu wybrana została baza MongoDB do produkcyjnego wdrożenia.