# Komentarz do zadania 

## Definicja tabel
Pierwsza oraz druga część listy skupiała się na implementacji zaporoponowanej tabeli z listy pierwszej.
W tej części, nie ma nic szczególnego.

## Ograniczenia 
Celem zadania trzeciego jest zastosowanie ograniczeń typu UNIQUE oraz CHECK.

### Zaproponowane UNIQUE wraz z wyjaśnieniem
- ```sql CONSTRAINT uk_country UNIQUE (Country) ``` - celem jest zapewnienie, że dany kraj nie zostanie wprowadzony dwukrotnie.
- ```sql CONSTRAINT uk_product_name UNIQUE (Product_Name)``` - nie ma dwóch produktów na świecie o nazwie Samsung Galaxy S21, są może różne warianty, ale nasz model nie przewiduje ich.

### Zaproponowane CHECK wraz z wyjaśnieniem
- ```sql CONSTRAINT chk_quantity CHECK (Quantity > 0) ``` - Wartość musi być większa niż 0. Gdy jest równa zero to nie został zamówiony produkt, dla ujmenych wartości nie ma to sensu.
- ```sql CONSTRAINT chk_shipping_cost CHECK (Shipping_Cost >= 0)``` - Zero gdy mam możliwość darmowej wysyłki. Wartości ujemne nie mają sensu.
- ```CONSTRAINT chk_discount CHECK (Discount >= 0.00 AND Discount <= 1.00)``` - Wartośći są sprzedziału z listy1 pliku data.xlsx. 
- ```CONSTRAINT chk_sales CHECK (Sales >= 0)```

## Procedury i funkcje
Jest to najbardziej złożone zadanie pod względem implementacji. Wymaga dużego skupienia na formatach i typach danych, które muszą być zgodne z plikiem data.xlsx z pierwszej listy.

## Główne procedury

### 1. Add_product
- Wykorzystuje dwie funkcje pomocnicze:
  - generate_category_code
  - generate_category_code
- Funkcje te generują w odpowiednim formacie podkategorie i kategorie
- Na końcu tworzą vi_product_ID w formie zgodnej z plikiem data.xlsx
- Zawiera obsługę exceptions informujących gdy coś pójdzie nie tak
- Wykorzystuje sequence zaczynający się od 1000 (zgodnie z data.xlsx)
- Posiada constrain sprawdzający poprawność formatu product_ID

### 2. Create_order
- Tworzy zamówienie w bazie danych
- Pozwala na podanie wszystkich wymaganych danych
- Proces tworzenia zamówienia:
  1. Generowanie country_code (potrzebny do ID zamówienia)
  2. Generowanie sequence_number
  3. Tworzenie v_order_id na podstawie:
     - v_country_code
     - Roku zamówienia
     - v_customer_id_for_order
     - v_sequence_number zaczynającego się 40000+
  4. Insertowanie danych
  5. Pętla FOR tworząca order_items (tabela relacji łącząca produkt z zamówieniem)
     - Zawiera quantity (ilość zamówionych produktów)

## Funkcje testujące
### test_order_creation
- Generuje:
  - kraj
  - użytkownika
  - wywołuje test_add_products()
  - tworzy zamówienie

### test_add_products
- Generuje 3 testowe produkty

## Dodatkowe zabezpieczenia
Zaimplementowane triggery (mimo istniejących constraintów) dla:
- ID produktów
- ID zamówień
- ID customers
Sprawdzają poprawność znaków w ID oraz format zapisu, by był zgodny z data.xlsx