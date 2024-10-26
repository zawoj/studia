Order_Date:
- Wiele zamówień może mieć tę samą datę
- Niska selektywność (kardynalność)
- Duża powtarzalność wartości

To rzeczywiście nie jest dobry kandydat na samodzielny indeks. Lepszym podejściem będzie:

1. Indeksowanie Order_ID (już mamy jako PK)
2. Rozważenie indeksu złożonego, gdzie Order_Date jest częścią większego indeksu, ale nie pierwszą kolumną
3. Skupienie się na kolumnach o większej unikalności

Poprawiona wersja indeksów:

```sql
/*
ZADANIE 03 - Indeksy i procedury analityczne dla bazy OrderDB

ANALIZA SELEKTYWNOŚCI DANYCH:

1. Wysoka selektywność (dobre do indeksowania):
   - Order_ID (unikalny)
   - Product_ID (unikalny)
   - Customer_ID (unikalny)
   - Product_Name (wysoka unikalność)

2. Niska selektywność (słabe do indeksowania):
   - Order_Date (powtarzające się daty)
   - Category (kilka kategorii)
   - Sub-Category (kilkanaście podkategorii)
   - Country (ograniczona liczba krajów)
   - Segment (tylko kilka wartości)
*/

-- 1. Indeks zgrupowany i niezgrupowany
/*
Uzasadnienie:
- Indeks zgrupowany (PRIMARY KEY) już istnieje na Order_ID
- Indeks niezgrupowany tworzymy na Product_Name ze względu na wysoką unikalność
  i częste wyszukiwania produktów po nazwie
*/

CREATE INDEX idx_product_name 
ON Products (Product_Name);

-- 2. Indeks gęsty i rzadki
/*
Uzasadnienie:
- Indeks gęsty na Customer_ID w Orders - często używany w złączeniach,
  wysoka unikalność
- Indeks rzadki na (Category, Sub-Category) - wspiera hierarchiczne 
  wyszukiwanie produktów, naturalna hierarchia danych
*/

CREATE INDEX idx_dense_orders_customer
ON Orders (Customer_ID);

CREATE INDEX idx_sparse_product_categories 
ON Products (Category, Sub-Category);

-- 3. Indeks kolumnowy
/*
Uzasadnienie:
Indeks kolumnowy najlepiej sprawdza się dla:
- Kolumn często używanych w agregacjach
- Kolumn używanych w analizach trendów
- Danych, które są głównie odczytywane

Sales i Profit są idealnymi kandydatami, bo:
- Często używane w agregacjach (SUM, AVG)
- Rzadko modyfikowane
- Kluczowe w analizach biznesowych
*/

CREATE INDEX idx_columnar_financial 
ON Orders USING columnar (
    Sales,
    Profit,
    Customer_ID  -- dodane dla lepszej efektywności grupowania po klientach
);

[Reszta kodu (procedury) pozostaje bez zmian]

/*
UZASADNIENIE ZMIANY PODEJŚCIA:

1. Usunięto indeks na Order_Date ponieważ:
   - Niska selektywność (wiele zamówień w tym samym dniu)
   - Lepiej obsługiwane przez skany sekwencyjne lub jako część większego indeksu
   - Koszt utrzymania indeksu przewyższałby korzyści

2. Skupiono się na kolumnach o wysokiej selektywności:
   - Product_Name (indeks niezgrupowany)
   - Customer_ID (indeks gęsty)
   - Hierarchia Category -> Sub-Category (indeks rzadki)

3. Indeks kolumnowy zoptymalizowano pod kątem:
   - Najczęstszych agregacji (Sales, Profit)
   - Grupowania po klientach (Customer_ID)

4. Wykorzystano naturalne właściwości danych:
   - Hierarchię kategorii produktów
   - Unikalność identyfikatorów
   - Wzorce dostępu do danych finansowych
*/
```

Ta wersja lepiej odzwierciedla rzeczywistą naturę danych i ich wykorzystanie w zapytaniach. Unikamy indeksowania kolumn o niskiej selektywności (jak Order_Date) i skupiamy się na tych, które rzeczywiście poprawią wydajność zapytań.