Zadanie_01 polega na przygotowaniu modelu implementacyjnego dla struktury z załączonego pliku data.xlsx. 

Model implementacyjny ma zawierać:

- tabele (encje) z kolumnami (atrybutami) i typami danych

- klucze główne i obce

- wymagane relacje (role) między tabelami

- określenie obowiązkowych wartości w kolumnach (NULL czy NOT NULL)

Przygotowany przez Państwa model implementacyjny ma pokrywać wszystkie wymagania zawarte w pliku (data.xlsx) tj. ma zawierać encje i atrybuty z trzech zakładek pliku tj. zamówienia, dane rynkowe oraz produkty i zostać załączony jako wynik Zadanie_01 w postaci dowolnego pliku graficznego lub formatu .pdf



# Fianl


Oczywiście, oto zmodyfikowana architektura z uwzględnieniem tabel "Addresses" i "Shipping Methods", wykorzystująca tylko istniejące pola z pliku data.xlsx oraz dodatkowe klucze:

1. Tabela "Customers":
   - Customer ID (klucz główny, typ: VARCHAR, NOT NULL)
   - Customer Name (typ: VARCHAR, NOT NULL)
   - Segment (typ: VARCHAR)

2. Tabela "Addresses":
   - Address ID (klucz główny, typ: VARCHAR, NOT NULL)
   - Customer ID (klucz obcy do tabeli "Customers", typ: VARCHAR, NOT NULL)
   - Postal Code (typ: VARCHAR)
   - City (typ: VARCHAR)
   - State (typ: VARCHAR)
   - Country (klucz obcy do tabeli "Geography", typ: VARCHAR, NOT NULL)

3. Tabela "Orders":
   - Order ID (klucz główny, typ: VARCHAR, NOT NULL)
   - Customer ID (klucz obcy do tabeli "Customers", typ: VARCHAR, NOT NULL)
   - Shipping Address ID (klucz obcy do tabeli "Addresses", typ: VARCHAR, NOT NULL)
   - Order Date (typ: DATE, NOT NULL)
   - Ship Date (typ: DATE)
   - Shipping Method ID (klucz obcy do tabeli "Shipping Methods", typ: VARCHAR, NOT NULL)
   - Product ID (klucz obcy do tabeli "Products", typ: VARCHAR, NOT NULL)
   - Sales (typ: DECIMAL)
   - Quantity (typ: INTEGER)
   - Discount (typ: DECIMAL)
   - Profit (typ: DECIMAL)
   - Shipping Cost (typ: DECIMAL)

4. Tabela "Shipping Methods":
   - Shipping Method ID (klucz główny, typ: VARCHAR, NOT NULL)
   - Ship Mode (typ: VARCHAR, NOT NULL)

5. Tabela "Geography":
   - Country (klucz główny, typ: VARCHAR, NOT NULL)
   - Market (typ: VARCHAR, NOT NULL)

6. Tabela "Products":
   - Product ID (klucz główny, typ: VARCHAR, NOT NULL)
   - Category (typ: VARCHAR, NOT NULL)
   - Sub-Category (typ: VARCHAR, NOT NULL)
   - Product Name (typ: VARCHAR, NOT NULL)

Relacje między tabelami:
- Tabela "Customers" ma relację jeden-do-wielu z tabelą "Addresses" poprzez klucz obcy "Customer ID".
- Tabela "Orders" ma relację wiele-do-jednego z tabelą "Customers" poprzez klucz obcy "Customer ID".
- Tabela "Orders" ma relację wiele-do-jednego z tabelą "Addresses" poprzez klucz obcy "Shipping Address ID".
- Tabela "Orders" ma relację wiele-do-jednego z tabelą "Shipping Methods" poprzez klucz obcy "Shipping Method ID".
- Tabela "Orders" ma relację wiele-do-jednego z tabelą "Products" poprzez klucz obcy "Product ID".
- Tabela "Addresses" ma relację wiele-do-jednego z tabelą "Geography" poprzez klucz obcy "Country".

W tej architekturze mamy oddzielne tabele "Addresses" i "Shipping Methods", które wykorzystują istniejące pola z pliku data.xlsx. Tabela "Addresses" przechowuje informacje o adresach dostawy dla każdego klienta, a tabela "Shipping Methods" zawiera dostępne metody wysyłki.

Dzięki tej strukturze możemy osiągnąć następujące korzyści:
- Klienci mogą mieć wiele adresów dostawy, co umożliwia im wybór odpowiedniego adresu podczas składania zamówienia.
- Metody wysyłki są oddzielone od zamówień, co ułatwia zarządzanie i dodawanie nowych opcji wysyłki w przyszłości.
- Można generować bardziej szczegółowe statystyki i analizy na podstawie adresów dostawy i metod wysyłki.

Pamiętaj, że ta architektura wymaga dodania dodatkowych kluczy (Address ID, Shipping Method ID) do istniejącej struktury danych, ale wykorzystuje tylko istniejące pola z pliku data.xlsx.