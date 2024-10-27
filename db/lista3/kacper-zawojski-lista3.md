Zadanie skupia się na zdefiniowaniu różnych typów indeksów oraz implementacji procedur analitycznych w bazie OrderDB. Na początku przeprowadziłem analizę selektywności danych, która pomogła w doborze odpowiednich kolumn do indeksowania. Zidentyfikowałem kolumny o wysokiej selektywności jak Order_ID, Product_ID czy Customer_ID, które są unikalne, oraz kolumny o niskiej selektywności jak Category czy Segment, gdzie wartości często się powtarzają.

W przypadku indeksu zgrupowanego, ze względu na specyfikę PostgreSQL, który nie posiada bezpośredniego odpowiednika jak w SQL Server, wykorzystałem fakt, że PRIMARY KEY automatycznie tworzy indeks zachowujący się podobnie. Dla indeksu niezgrupowanego wybrałem kombinację Order_Date i Ship_Date, co uzasadnione jest częstym wykorzystaniem tych dat w zapytaniach analitycznych oraz analizach czasów dostaw.

Przechodząc do indeksów gęstego i rzadkiego, zdecydowałem się na utworzenie indeksu gęstego na Customer_ID w tabeli Orders, co wspiera częste operacje złączeń. Dla indeksu rzadkiego wybrałem kombinację Category i Sub-Category, wykorzystując naturalną hierarchię danych produktowych.

Szczególną uwagę poświęciłem indeksowi kolumnowemu, implementując go jako BRIN na kolumnach finansowych (Sales, Profit) oraz Order_Date. BRIN jest szczególnie efektywny dla danych analitycznych i naturalnie skorelowanych, oferując dobry kompromis między rozmiarem indeksu a wydajnością zapytań.

Zaimplementowałem również dwie procedury analityczne. Pierwsza zwraca szczegółowe informacje o zamówieniach dla konkretnej podkategorii w określonym kraju. Druga procedura fokusuje się na segmencie Consumer, zwracając dwa najnowsze zamówienia dla każdego klienta z wykorzystaniem techniki okien (window functions).

