
-- ANALIZA SELEKTYWNOŚCI DANYCH:

-- 1. Wysoka selektywność (dobre do indeksowania):
--    - Order_ID (unikalny)
--    - Product_ID (unikalny)
--    - Customer_ID (unikalny)
--    - Product_Name (wysoka unikalność)

-- 2. Niska selektywność (słabe do indeksowania):
--    - Order_Date (powtarzające się daty)
--    - Category (kilka kategorii)
--    - Sub-Category (kilkanaście podkategorii)
--    - Country (ograniczona liczba krajów)
--    - Segment (tylko kilka wartości)


-- W PostgreSQL nie ma bezpośredniego odpowiednika indeksu zgrupowanego jak w SQL Server,
-- ale PRIMARY KEY automatycznie tworzy indeks, który zachowuje się podobnie.



-- - Indeks niezgrupowany tworzymy na Product_Name ze względu na wysoką unikalność i częste wyszukiwania produktów po nazwie
CREATE INDEX idx_product_name 
ON Products (Product_Name);


-- 2. Indeks gęsty i rzadki
/*
Uzasadnienie:
- Indeks gęsty na Customer_ID w Orders - często używany w złączeniach, wysoka unikalność
- Indeks rzadki na (Category, Sub-Category) - wspiera hierarchiczne 
  wyszukiwanie produktów, naturalna hierarchia danych
*/

CREATE INDEX idx_dense_orders_customer
ON Orders (Customer_ID);

CREATE INDEX idx_sparse_product_categories 
ON Products (Category, Sub_Category);


CREATE EXTENSION citus;

-- 3. Indeks kolumnowy
/*
Uzasadnienie:
Sales i Profit są idealnymi kandydatami, bo:
- Często używane w agregacjach (SUM, AVG)
- Rzadko modyfikowane
- Kluczowe w analizach biznesowych
*/
CREATE INDEX idx_columnar_financial 
ON Orders USING columnar (
    Sales,
    Profit,
    Customer_ID 
);

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