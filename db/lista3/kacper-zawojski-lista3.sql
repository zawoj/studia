


-- - Indeks niezgrupowany ----------------------------------------------
CREATE INDEX idx_product_name 
ON Products (Product_Name);


-- 2. Indeks gęsty i rzadki ----------------------------------------------

CREATE INDEX idx_dense_orders_customer
ON Orders (Customer_ID);

CREATE INDEX idx_sparse_product_categories 
ON Products (Category, Sub_Category);

-- Indeks kolumnowy ----------------------------------------------

CREATE INDEX idx_orders_financial_brin ON Orders 
USING BRIN (
    Order_Date,
    Sales,
    Profit
) WITH (pages_per_range = 128);


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
        RankedOrders.Order_ID, 
        RankedOrders.Order_Date,
        RankedOrders.Product_Name,
        RankedOrders.Sales,
        RankedOrders.Customer_Name,
        RankedOrders.rn
    FROM RankedOrders
    WHERE rn <= 2
    ORDER BY Customer_Name, Order_Date DESC;
END;
$$ LANGUAGE plpgsql;

-- Przykłady użycia:

SELECT * FROM get_orders_by_subcategory_and_country('Phones', 'Poland');


SELECT * FROM get_latest_consumer_orders();