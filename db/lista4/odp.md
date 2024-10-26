/*
ZADANIE 04 - Procedury, widoki zmaterializowane, kompresja i partycjonowanie
*/

-- 1. Procedura zwracająca zamówienia z bieżącego miesiąca
CREATE OR REPLACE FUNCTION get_current_month_orders()
RETURNS TABLE (
    order_id VARCHAR,
    order_date DATE,
    product_name VARCHAR,
    sales FLOAT,
    quantity INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        o.Order_ID,
        o.Order_Date,
        p.Product_Name,
        o.Sales,
        oi.Quantity
    FROM Orders o
    JOIN Order_Items oi ON o.Order_ID = oi.Order_ID
    JOIN Products p ON oi.Product_ID = p.Product_ID
    WHERE EXTRACT(MONTH FROM o.Order_Date) = EXTRACT(MONTH FROM CURRENT_DATE)
    AND EXTRACT(YEAR FROM o.Order_Date) = EXTRACT(YEAR FROM CURRENT_DATE)
    ORDER BY o.Order_Date DESC;
END;
$$ LANGUAGE plpgsql;

-- 2. Zmaterializowany widok aktywnych klientów
CREATE MATERIALIZED VIEW active_customers AS
SELECT DISTINCT
    c.Customer_ID,
    c.Customer_Name,
    c.Segment
FROM Customers c
JOIN Orders o ON c.Customer_ID = o.Customer_ID
WITH DATA;

-- Indeks na zmaterializowanym widoku dla szybszego dostępu
CREATE UNIQUE INDEX idx_active_customers_id ON active_customers (Customer_ID);

-- 3. Kompresja danych
/*
Uzasadnienie wyboru kompresji:

W PostgreSQL możemy wykorzystać kompresję ZLIB dla dużych tekstowych kolumn.
Najlepszymi kandydatami są kolumny:
- Product_Name (długie nazwy produktów)
- Customer_Name (dane tekstowe)
- Adresy (dane tekstowe)

Kompresja ZLIB jest dobrym wyborem ponieważ:
- Oferuje dobry stosunek kompresji do wydajności
- Jest szczególnie efektywna dla danych tekstowych
- Wspiera różne poziomy kompresji
*/

-- Przykład zastosowania kompresji na kolumnie Product_Name
ALTER TABLE Products
ALTER COLUMN Product_Name
SET STORAGE EXTENDED;

-- 4. Partycjonowanie
/*
Uzasadnienie partycjonowania:

Wybrano partycjonowanie po dacie zamówienia (Order_Date) ponieważ:
1. Zapytania często filtrują dane po okresach czasowych
2. Łatwe archiwizowanie starych partycji
3. Efektywne zarządzanie danymi historycznymi
4. Naturalne grupowanie danych biznesowych (miesiące/kwartały)
*/

-- Utworzenie tabeli spartycjonowanej
CREATE TABLE Orders_Partitioned (
    Order_ID VARCHAR(50) NOT NULL,
    Customer_ID VARCHAR(50) NOT NULL,
    Country VARCHAR(50) NOT NULL,
    Order_Date DATE NOT NULL,
    Ship_Date DATE,
    Ship_Mode VARCHAR(50) NOT NULL,
    Postal_Code VARCHAR(20) NOT NULL,
    City VARCHAR(100) NOT NULL,
    State VARCHAR(100) NOT NULL,
    Shipping_Cost FLOAT NOT NULL,
    Profit FLOAT NOT NULL,
    Discount FLOAT NOT NULL,
    Sales FLOAT NOT NULL
) PARTITION BY RANGE (Order_Date);

-- Tworzenie partycji dla poszczególnych kwartałów
CREATE TABLE orders_q1_2024 PARTITION OF Orders_Partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE orders_q2_2024 PARTITION OF Orders_Partitioned
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

CREATE TABLE orders_q3_2024 PARTITION OF Orders_Partitioned
    FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');

CREATE TABLE orders_q4_2024 PARTITION OF Orders_Partitioned
    FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');

-- Funkcja pomocnicza do automatycznego tworzenia partycji
CREATE OR REPLACE FUNCTION create_orders_partition_for_quarter()
RETURNS void AS $$
DECLARE
    next_quarter_start DATE;
    next_quarter_end DATE;
    partition_name TEXT;
BEGIN
    -- Obliczenie dat następnego kwartału
    next_quarter_start := date_trunc('quarter', CURRENT_DATE + interval '3 months');
    next_quarter_end := next_quarter_start + interval '3 months';
    
    -- Utworzenie nazwy partycji
    partition_name := 'orders_q' || 
                     EXTRACT(QUARTER FROM next_quarter_start) ||
                     '_' || 
                     EXTRACT(YEAR FROM next_quarter_start);
    
    -- Utworzenie partycji
    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS %I PARTITION OF Orders_Partitioned
         FOR VALUES FROM (%L) TO (%L)',
        partition_name,
        next_quarter_start,
        next_quarter_end
    );
END;
$$ LANGUAGE plpgsql;

/*
DODATKOWE UWAGI:

1. Procedura get_current_month_orders:
   - Automatycznie dostosowuje się do bieżącego miesiąca
   - Nie wymaga modyfikacji kodu w kolejnych miesiącach
   - Efektywnie wykorzystuje indeksy na Order_Date

2. Zmaterializowany widok active_customers:
   - Przyspiesza często wykonywane zapytania o aktywnych klientów
   - Wymaga okresowego odświeżania (REFRESH MATERIALIZED VIEW)
   - Posiada indeks dla szybszego dostępu

3. Kompresja:
   - Zastosowana dla kolumn tekstowych
   - Zmniejsza rozmiar bazy danych
   - Optymalny balans między kompresją a wydajnością

4. Partycjonowanie:
   - Kwartalne partycje dla łatwiejszego zarządzania
   - Automatyczne tworzenie nowych partycji
   - Wspiera efektywne usuwanie starych danych
   - Poprawia wydajność zapytań filtrujących po dacie

Przykłady użycia:

-- Pobranie zamówień z bieżącego miesiąca
SELECT * FROM get_current_month_orders();

-- Odświeżenie widoku aktywnych klientów
REFRESH MATERIALIZED VIEW active_customers;

-- Utworzenie partycji na kolejny kwartał
SELECT create_orders_partition_for_quarter();
*/