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



CREATE MATERIALIZED VIEW active_customers AS
SELECT DISTINCT
    c.Customer_ID,
    c.Customer_Name,
    c.Segment
FROM Customers c
JOIN Orders o ON c.Customer_ID = o.Customer_ID
WITH DATA;

CREATE UNIQUE INDEX idx_active_customers_id ON active_customers (Customer_ID);


ALTER TABLE Customers
ALTER COLUMN Customer_Name
SET STORAGE EXTENDED;



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

CREATE TABLE orders_q1_2024 PARTITION OF Orders_Partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE orders_q2_2024 PARTITION OF Orders_Partitioned
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

CREATE TABLE orders_q3_2024 PARTITION OF Orders_Partitioned
    FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');

CREATE TABLE orders_q4_2024 PARTITION OF Orders_Partitioned
    FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');

CREATE OR REPLACE FUNCTION create_orders_partition_for_quarter()
RETURNS void AS $$
DECLARE
    next_quarter_start DATE;
    next_quarter_end DATE;
    partition_name TEXT;
BEGIN
    next_quarter_start := date_trunc('quarter', CURRENT_DATE + interval '3 months');
    next_quarter_end := next_quarter_start + interval '3 months';
    
    partition_name := 'orders_q' || 
                     EXTRACT(QUARTER FROM next_quarter_start) ||
                     '_' || 
                     EXTRACT(YEAR FROM next_quarter_start);
    
    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS %I PARTITION OF Orders_Partitioned
         FOR VALUES FROM (%L) TO (%L)',
        partition_name,
        next_quarter_start,
        next_quarter_end
    );
END;
$$ LANGUAGE plpgsql;





-- Pobranie zamówień z bieżącego miesiąca
SELECT * FROM get_current_month_orders();

-- Odświeżenie widoku aktywnych klientów
REFRESH MATERIALIZED VIEW active_customers;

-- Wyświetlenie widoku aktywnych klientów
SELECT * FROM active_customers;

-- Utworzenie partycji na kolejny kwartał
SELECT create_orders_partition_for_quarter();