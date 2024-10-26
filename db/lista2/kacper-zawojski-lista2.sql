-- Active: 1729932596833@@127.0.0.1@5432@OrderDB@public


-- TWORZENIE TABEL ------------------------------------------------------------

CREATE TABLE Geography (
    Country VARCHAR(50) PRIMARY KEY NOT NULL,
    Market VARCHAR(50) NOT NULL,
    CONSTRAINT uk_country UNIQUE (Country)
);


CREATE TABLE Customers (
    Customer_ID VARCHAR(50) PRIMARY KEY NOT NULL,
    Customer_Name VARCHAR(100) NOT NULL,
    Segment VARCHAR(50) NOT NULL
);

CREATE TABLE Products (
    Product_ID VARCHAR(50) PRIMARY KEY NOT NULL,
    Category VARCHAR(50) NOT NULL,
    Sub_Category VARCHAR(50) NOT NULL,
    Product_Name VARCHAR(100) NOT NULL,
    CONSTRAINT uk_product_name UNIQUE (Product_Name)
);

CREATE SEQUENCE product_sequence
    START WITH 1000
    INCREMENT BY 1
    NO MAXVALUE;

CREATE TABLE Orders (
    Order_ID VARCHAR(50) PRIMARY KEY NOT NULL,
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
    Sales FLOAT NOT NULL,
    CONSTRAINT fk_customer FOREIGN KEY (Customer_ID) REFERENCES Customers(Customer_ID),
    CONSTRAINT fk_country FOREIGN KEY (Country) REFERENCES Geography(Country),
    CONSTRAINT chk_shipping_cost CHECK (Shipping_Cost >= 0),
    CONSTRAINT chk_sales CHECK (Sales >= 0),
    CONSTRAINT chk_discount CHECK (Discount >= 0.00 AND Discount <= 1.00)
);

CREATE SEQUENCE order_sequence
    START WITH 40000
    INCREMENT BY 1
    NO MAXVALUE;

CREATE TABLE Order_Items (
    Order_ID VARCHAR(50) NOT NULL,
    Product_ID VARCHAR(50) NOT NULL,
    Quantity INT NOT NULL,
    PRIMARY KEY (Order_ID, Product_ID),
    CONSTRAINT fk_order FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID),
    CONSTRAINT fk_product FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID),
    CONSTRAINT chk_quantity CHECK (Quantity > 0)
);


-- CONSRAINTS ------------------------------------------------------------
CREATE OR REPLACE FUNCTION is_valid_customer_id(id VARCHAR) 
RETURNS BOOLEAN AS $$
BEGIN
    RETURN id ~ '^[A-Z]{2}-[0-9]{7}$';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION is_valid_order_id(id VARCHAR) 
RETURNS BOOLEAN AS $$
BEGIN
    RETURN id ~ '^[A-Z]{2}-[0-9]{4}-[A-Z0-9]+-[0-9]{5}$';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION is_valid_product_id(id VARCHAR) 
RETURNS BOOLEAN AS $$
BEGIN
    RETURN id ~ '^[A-Z]{3}-[A-Z]{2}-[0-9]{4}$';
END;
$$ LANGUAGE plpgsql;


-- APPLY CONSTRAINTS ------------------------------------------------------------
ALTER TABLE Customers
    ADD CONSTRAINT check_customer_id_format 
    CHECK (is_valid_customer_id(Customer_ID));

ALTER TABLE Orders
    ADD CONSTRAINT check_order_id_format 
    CHECK (is_valid_order_id(Order_ID));

ALTER TABLE Products
    ADD CONSTRAINT check_product_id_format 
    CHECK (is_valid_product_id(Product_ID));




-- TWORZENIE PRODUKTU ------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_category_code(category_name VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    RETURN UPPER(LEFT(REGEXP_REPLACE(category_name, '[^a-zA-Z]', '', 'g'), 3));
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_subcategory_code(subcategory_name VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    RETURN UPPER(LEFT(REGEXP_REPLACE(subcategory_name, '[^a-zA-Z]', '', 'g'), 2));
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE add_product(
    p_category VARCHAR,
    p_subcategory VARCHAR,
    p_product_name VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id VARCHAR(50);
    v_category_code VARCHAR(3);
    v_subcategory_code VARCHAR(2);
    v_sequence_number INT;
BEGIN
    v_category_code := generate_category_code(p_category);
    v_subcategory_code := generate_subcategory_code(p_subcategory);
    
    SELECT nextval('product_sequence') INTO v_sequence_number;
    
    v_product_id := FORMAT('%s-%s-%s',
        v_category_code,
        v_subcategory_code,
        LPAD(v_sequence_number::TEXT, 4, '0')
    );
    
    -- Wstawienie nowego produktu
    INSERT INTO Products (Product_ID, Category, Sub_Category, Product_Name)
    VALUES (v_product_id, p_category, p_subcategory, p_product_name);
    
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Błąd podczas dodawania produktu: %', SQLERRM;
END;
$$;

-- TWORZENIE ZAMÓIENIA ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE create_order(
    p_customer_id VARCHAR(50),
    p_country VARCHAR(50),
    p_ship_mode VARCHAR(50),
    p_postal_code VARCHAR(20),
    p_city VARCHAR(100),
    p_state VARCHAR(100),
    p_products_array JSON
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id VARCHAR(50);
    v_product_record JSON;
    v_country_code VARCHAR(2);
    v_sequence_number INT;
    v_customer_id_for_order VARCHAR(50);
BEGIN

    v_country_code := UPPER(LEFT(p_country, 2));


    SELECT COALESCE(MAX(CAST(SPLIT_PART(Order_ID, '-', 4) AS INTEGER)), 40000) + 1
    INTO v_sequence_number
    FROM Orders;

    v_customer_id_for_order := REPLACE(p_customer_id, '-', '');

    v_order_id := FORMAT('%s-%s-%s-%s',
        v_country_code,
        EXTRACT(YEAR FROM CURRENT_DATE)::TEXT,
        v_customer_id_for_order,
        v_sequence_number::TEXT
    );
    
    INSERT INTO Orders (
        Order_ID, Customer_ID, Country, Order_Date, Ship_Mode,
        Postal_Code, City, State, Shipping_Cost, Profit, Discount, Sales
    )
    VALUES (
        v_order_id, p_customer_id, p_country, CURRENT_DATE, p_ship_mode,
        p_postal_code, p_city, p_state, 0, 0, 0, 0
    );


    FOR v_product_record IN SELECT * FROM json_array_elements(p_products_array)
    LOOP
        INSERT INTO Order_Items (Order_ID, Product_ID, Quantity)
        VALUES (
            v_order_id,
            (v_product_record->>'product_id')::VARCHAR,
            (v_product_record->>'quantity')::INT
        );
    END LOOP;

EXCEPTION 
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error when creating an order: %', SQLERRM;
END;
$$;


-- TWORZENIE CUSTOMERA ------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_customer_id(p_first_name VARCHAR, p_last_name VARCHAR)
RETURNS VARCHAR AS $$
DECLARE
    v_initials VARCHAR(2);
    v_sequence_number INT;
    v_customer_id VARCHAR(50);
BEGIN
    v_initials := UPPER(LEFT(p_first_name, 1) || LEFT(p_last_name, 1));
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(Customer_ID FROM 4) AS INTEGER)), 2170000)
    INTO v_sequence_number
    FROM Customers
    WHERE Customer_ID LIKE v_initials || '-%';
    
    v_customer_id := FORMAT('%s-%s', v_initials, (v_sequence_number + 1)::TEXT);
    
    RETURN v_customer_id;
END;
$$ LANGUAGE plpgsql;


-- TRIGGERS ------------------------------------------------------------
CREATE OR REPLACE FUNCTION verify_customer_id()
RETURNS TRIGGER AS $$
BEGIN
    DECLARE
        expected_initials VARCHAR(2);
        actual_initials VARCHAR(2);
        name_parts TEXT[];
    BEGIN
        name_parts := string_to_array(NEW.Customer_Name, ' ');
        
        expected_initials := UPPER(LEFT(name_parts[1], 1) || LEFT(name_parts[array_length(name_parts, 1)], 1));
        
        actual_initials := SPLIT_PART(NEW.Customer_ID, '-', 1);
        
        IF expected_initials != actual_initials THEN
            RAISE EXCEPTION 'Nieprawidłowe inicjały w Customer ID. Oczekiwano: %, otrzymano: %', 
                expected_initials, actual_initials;
        END IF;
    END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION verify_order_id()
RETURNS TRIGGER AS $$
BEGIN
    DECLARE
        order_year VARCHAR(4);
        actual_year VARCHAR(4);
        customer_id_from_order VARCHAR(50);
        customer_id_normalized VARCHAR(50);
    BEGIN
        -- Sprawdzenie roku
        order_year := SPLIT_PART(NEW.Order_ID, '-', 2);
        actual_year := TO_CHAR(NEW.Order_Date, 'YYYY');
        
        IF order_year != actual_year THEN
            RAISE EXCEPTION 'Nieprawidłowy rok w Order ID. Oczekiwano: %, otrzymano: %', 
                actual_year, order_year;
        END IF;
        
        -- Normalizacja Customer ID (usunięcie myślnika)
        customer_id_from_order := SPLIT_PART(NEW.Order_ID, '-', 3);
        customer_id_normalized := REPLACE(NEW.Customer_ID, '-', '');
        
        -- Sprawdzenie czy znormalizowane ID są zgodne
        IF customer_id_from_order != customer_id_normalized THEN
            RAISE EXCEPTION 'Nieprawidłowy Customer ID w Order ID. Oczekiwano: %, otrzymano: %', 
                customer_id_normalized, customer_id_from_order;
        END IF;
    END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION verify_product_id()
RETURNS TRIGGER AS $$
BEGIN
    DECLARE
        expected_category_code VARCHAR(3);
        actual_category_code VARCHAR(3);
        expected_subcategory_code VARCHAR(2);
        actual_subcategory_code VARCHAR(2);
    BEGIN
        expected_category_code := generate_category_code(NEW.Category);
        expected_subcategory_code := generate_subcategory_code(NEW.Sub_Category);
        
        actual_category_code := SPLIT_PART(NEW.Product_ID, '-', 1);
        actual_subcategory_code := SPLIT_PART(NEW.Product_ID, '-', 2);
        
        IF expected_category_code != actual_category_code OR 
           expected_subcategory_code != actual_subcategory_code THEN
            RAISE EXCEPTION 'Nieprawidłowe kody kategorii w Product ID. Oczekiwano: %-%, otrzymano: %-%', 
                expected_category_code, expected_subcategory_code, 
                actual_category_code, actual_subcategory_code;
        END IF;
    END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Utworzenie triggerów ------------------------------------------------------------
CREATE TRIGGER check_customer_id_consistency
    BEFORE INSERT OR UPDATE ON Customers
    FOR EACH ROW
    EXECUTE FUNCTION verify_customer_id();

CREATE TRIGGER check_order_id_consistency
    BEFORE INSERT OR UPDATE ON Orders
    FOR EACH ROW
    EXECUTE FUNCTION verify_order_id();

CREATE TRIGGER check_product_id_consistency
    BEFORE INSERT OR UPDATE ON Products
    FOR EACH ROW
    EXECUTE FUNCTION verify_product_id();

-- TESTOWANIE ------------------------------------------------------------

CREATE OR REPLACE PROCEDURE test_order_creation()
LANGUAGE plpgsql
AS $$
DECLARE
    v_first_product_id VARCHAR(50);
    v_second_product_id VARCHAR(50);
    v_customer_id VARCHAR(50);
BEGIN
    INSERT INTO Geography VALUES ('Poland', 'EU') ON CONFLICT DO NOTHING;
    
    v_customer_id := generate_customer_id('John', 'Smith');
    
    INSERT INTO Customers VALUES 
    (v_customer_id, 'John Smith', 'Consumer') ON CONFLICT DO NOTHING;
    
    CALL test_add_products();
    
    SELECT Product_ID INTO v_first_product_id
    FROM Products
    ORDER BY Product_ID DESC
    LIMIT 1;
    
    SELECT Product_ID INTO v_second_product_id
    FROM Products
    WHERE Product_ID < v_first_product_id
    ORDER BY Product_ID DESC
    LIMIT 1;

    CALL create_order(
        v_customer_id,
        'Poland',
        'Standard',
        '00-001',
        'Warsaw',
        'Mazowieckie',
        format('[
            {"product_id": "%s", "quantity": 1},
            {"product_id": "%s", "quantity": 2}
        ]', v_first_product_id, v_second_product_id)::JSON
    );
END;
$$;

CREATE OR REPLACE PROCEDURE test_add_products()
LANGUAGE plpgsql
AS $$
BEGIN
    CALL add_product(
        'Furniture',
        'Bookcases',
        'Atlantic Metals Mobile 2-Shelf Bookcases, Custom Colors'
    );
    
    CALL add_product(
        'Furniture',
        'Bookcases',
        'Atlantic Metals Mobile 3-Shelf Bookcases, Custom Colors'
    );
    
    CALL add_product(
        'Technology',
        'Phones',
        'Samsung Galaxy S21'
    );
    
    RAISE NOTICE 'Dodane produkty:';
    RAISE NOTICE '%', (SELECT string_agg(Product_ID || ' - ' || Product_Name, E'\n')
                      FROM Products
                      WHERE Product_ID IN (
                          SELECT Product_ID 
                          FROM Products 
                          ORDER BY Product_ID DESC 
                          LIMIT 3
                      ));
END;
$$;


-- RUN TEST ORDER CALL test_order_creation();
-- RUN TEST CREATE PRODUCT CALL test_add_products();
