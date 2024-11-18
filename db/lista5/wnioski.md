# Wprowadzenie

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
Dla testów utworzyłem kilkanaście zapytań <TUTAJ KRÓTKI OGÓLNY OPIS>.
W pierwszym odpaleniu część odpowiedzialna za ustawianie indeksów została zakomentowana.

Rezultaty:
- Średni czas trwania zapytania
- Najdłuższy czas
- Najkrótszy czas

Każde zapytanie zostało wykonane 10 razy.

Wyniki znajdują się w dwóch plikach:
- `query_stats.json` dla zapytań bez indeksów
- `query_stats-index.json` dla zapytań z indeksami

Widać, że tam gdzie dodano indeksy, wyniki znacząco się poprawiły. Jednak tam gdzie ich nie dodałem, czas nieznacznie się pogorszył. Tutaj wysuwa się pytanie - czy dodanie indeksów do jednych pól/modeli może spowodować gorsze wyniki zapytań do innych?

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