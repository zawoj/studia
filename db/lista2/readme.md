Zadanie 02 polega na implementacji modelu utworzonego w zadaniu 01.

Proszę stworzyć fizycznie bazę danych o nazwie OrderDB używając dowolnego (ulubionego) silnika baz relacyjnych (np. MS SQL Server Developer), która powinna zawierać następujące obiekty:
1. Wszystkie tabele oraz związki  wraz z kluczami modelu implementacyjnego z poprzedniego zadania. 
2. Określenie obowiązkowych wartości we wszystkich kolumnach (NULL lub NOT NULL)
3. Co najmniej jedno ograniczenie typu UNIQUE (np. na kolumnie Order ID reprezentującej wartość biznesową zamówienia) oraz co najmniej dwa ograniczenia CHECK (np. brak możliwości wprowadzenia zamówienia z wartością ujemną w kolumnie Quantity)
4. Implementację procedury (procedur) i/lub funkcji, która umożliwi wprowadzenie zamówienia  dla danego klienta, na co najmniej dwa różne produkty w ramach konkretnego rynku. Ponadto, należy użyć jawnej transakcji w kodzie do obsługi tej logiki wstawiającej zamówienie do bazy danych OrderDB.
Uwaga: niniejsza logika procedury (funkcji) ma realizować możliwość wprowadzenia kompletnego zamówienia do bazy danych OrderDB tj. ma dawać sposobność wprowadzenia danych do wszystkich zainteresowanych tabel bazy danych OrderDB tj. kategorie, podkategorie, produkty, rynki, klienci, zamówienia itp.
5. Implementację procedury i/lub funkcji testującej w całości punkt 4 z kompletnym zamówieniem, które będzie można wprowadzić do bazy danych OrderDB.

Wygenerowany skrypt o rozszerzeniu .sql zawierający realizację punktów 1-5 należy załączyć jako wynik Zadanie_02.