Zadanie polega na realizacji następujących punktów w bazie OrderDB
1. Utworzenie procedury lub funkcji zwracającej wszystkie zamówienia (wymagane kolumny wynikowe: order id, order date, product name, sales, quantity) z bieżącego miesiąca. Uwaga: należy stworzyć dynamiczny warunek na aktualny miesiąc, tak aby logika procedury (lub funkcji) była możliwa do wykorzystania w kolejnych mesiącach bez żadnej ingenerencji programisty w kod.

2. Utworzenie zmaterializowanego widoku zwracającego wszystkich klientów (wymagane kolumny: customer id, customer name, segment), którzy złożyli co najmniej jedno zamówienie.

3. Włączenie kompresji na dowolnej strukturze bazy (w komentarzu skryptu wynikowego dla Zadanie 04 należy uzsadnić typ zastosowanej kompresji)

4. Włączenie partycjonowania (w komentarzu skryptu wynikowego dla Zadanie 04 należy uzasadnić rodzaj zastasowanego partycjonowania oraz jego praktyczne przeznaczenie)

Plik o rozszerzeniu .sql zawierający realizację punktów 1-4 należy załączyć jako wynik Zadania 04.