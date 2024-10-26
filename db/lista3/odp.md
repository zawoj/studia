Oto rozwiązanie zadania dla bazy OrderDB w PostgreSQL:

```sql
/*
ZADANIE 03 - Indeksy i procedury analityczne dla bazy OrderDB
*/

-- 1. Indeksy zgrupowany i niezgrupowany
/*
W PostgreSQL nie ma bezpośredniego odpowiednika indeksu zgrupowanego jak w SQL Server,
ale PRIMARY KEY automatycznie tworzy indeks, który zachowuje się podobnie.
Dodatkowo tworzymy indeks niezgrupowany na często wyszukiwanych kolumnach.

Uzasadnienie:
- Order_Date jest często używane w zapytaniach analitycznych i filtrowania
- Ship_Date jest używane do analiz czasów dostaw
- Połączenie tych dat w jednym indeksie pozwala na efektywne wyszukiwanie zamówień w określonych przedziałach czasowych
*/

-- Indeks niezgrupowany na datach w Orders
CREATE INDEX idx_orders_dates 
ON Orders (Order_Date, Ship_Date);

-- 2. Indeksy gęsty i rzadki
/*
Uzasadnienie:
- Indeks gęsty na Product_Name, bo każda wartość jest unikalna i często wyszukiwana
- Indeks rzadki na Category, bo ma niewiele unikalnych wartości i jest używana do grupowania
*/

-- Indeks gęsty na Product_Name
CREATE INDEX idx_dense_product_name 
ON Products (Product_Name);

-- Indeks rzadki na Category z INCLUDE
CREATE INDEX idx_sparse_category 
ON Products (Category) INCLUDE (Sub_Category);

-- 3. Indeks kolumnowy
/*
Uzasadnienie:
Indeks kolumnowy jest szczególnie użyteczny dla:
- Analiz agregujących duże ilości danych
- Zapytań raportowych wykorzystujących niewiele kolumn z tabeli
- Danych, które rzadko są modyfikowane
- Kolumn często używanych w klauzulach GROUP BY i agregacjach

W tym przypadku tworzymy indeks kolumnowy na kolumnach używanych w analizach sprzedażowych
*/

CREATE INDEX idx_columnar_sales_analysis 
ON Orders USING columnar (
    Sales,
    Profit,
    Discount,
    Order_Date
);

-- 4. Procedura zwracająca zamówienia dla podkategorii i kraju
CREATE OR REPLACE FUNCTION get_orders_by_subcategory_and_country(
    p_subcategory VARCHAR,
    p_country VARCHAR
)
RETURNS TABLE (
    order_id VARCHAR,
    order_date DATE,
    ship_date DATE,
    product_name VARCHAR,
    sales FLOAT,
    quantity INT,
    profit FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        o.Order_ID,
        o.Order_Date,
        o.Ship_Date,
        p.Product_Name,
        o.Sales,
        oi.Quantity,
        o.Profit
    FROM Orders o
    JOIN Order_Items oi ON o.Order_ID = oi.Order_ID
    JOIN Products p ON oi.Product_ID = p.Product_ID
    WHERE p.Sub_Category = p_subcategory
    AND o.Country = p_country
    ORDER BY o.Order_Date DESC;
END;
$$ LANGUAGE plpgsql;

-- 5. Procedura zwracająca dwa najnowsze zamówienia dla klientów Consumer
CREATE OR REPLACE FUNCTION get_latest_consumer_orders()
RETURNS TABLE (
    order_id VARCHAR,
    order_date DATE,
    product_name VARCHAR,
    sales FLOAT,
    customer_name VARCHAR,
    row_num BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH RankedOrders AS (
        SELECT 
            o.Order_ID,
            o.Order_Date,
            p.Product_Name,
            o.Sales,
            c.Customer_Name,
            ROW_NUMBER() OVER (
                PARTITION BY c.Customer_ID 
                ORDER BY o.Order_Date DESC, o.Order_ID DESC
            ) as rn
        FROM Orders o
        JOIN Order_Items oi ON o.Order_ID = oi.Order_ID
        JOIN Products p ON oi.Product_ID = p.Product_ID
        JOIN Customers c ON o.Customer_ID = c.Customer_ID
        WHERE c.Segment = 'Consumer'
    )
    SELECT 
        Order_ID,
        Order_Date,
        Product_Name,
        Sales,
        Customer_Name,
        rn
    FROM RankedOrders
    WHERE rn <= 2
    ORDER BY Customer_Name, Order_Date DESC;
END;
$$ LANGUAGE plpgsql;

-- Przykłady użycia:
/*
-- Wyszukiwanie zamówień dla podkategorii i kraju
SELECT * FROM get_orders_by_subcategory_and_country('Phones', 'United States');

-- Pobieranie dwóch najnowszych zamówień dla klientów Consumer
SELECT * FROM get_latest_consumer_orders();
*/

/*
Dodatkowe indeksy wspierające zapytania:
*/

-- Indeks dla wyszukiwania zamówień po podkategorii i kraju
CREATE INDEX idx_orders_subcategory_country
ON Orders (Country)
INCLUDE (Order_Date, Ship_Date, Sales, Profit);

CREATE INDEX idx_products_subcategory
ON Products (Sub_Category)
INCLUDE (Product_Name);

-- Indeks dla wyszukiwania zamówień konsumenckich
CREATE INDEX idx_customers_segment
ON Customers (Segment)
INCLUDE (Customer_Name);

CREATE INDEX idx_orders_customer_date
ON Orders (Customer_ID, Order_Date DESC)
INCLUDE (Sales);
```

Dodatkowe uwagi:
1. Wszystkie indeksy są zoptymalizowane pod kątem najczęstszych zapytań
2. Użyto INCLUDE dla dodatkowych kolumn, aby uniknąć lookup-ów
3. Indeksy kolumnowe są szczególnie przydatne dla analiz historycznych
4. Procedury zawierają optymalne ścieżki dostępu do danych
5. Dodano indeksy wspierające konkretne przypadki użycia

Przed wdrożeniem należy przetestować wydajność na reprezentatywnym zbiorze danych.

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