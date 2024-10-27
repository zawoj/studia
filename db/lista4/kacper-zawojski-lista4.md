# Komentarz do zadania

Zadanie skupia się na implementacji zaawansowanych funkcjonalności bazodanowych w OrderDB, obejmujących dynamiczne zapytania, materializację widoków oraz optymalizację przechowywania danych.

Pierwszym elementem jest funkcja zwracająca zamówienia z bieżącego miesiąca. Wykorzystałem tutaj funkcję EXTRACT do wyodrębnienia miesiąca i roku z daty zamówienia oraz bieżącej daty. Takie podejście zapewnia, że funkcja będzie działać poprawnie w kolejnych miesiącach bez konieczności modyfikacji kodu.

Następnie zaimplementowałem zmaterializowany widok active_customers, który przechowuje informacje o klientach posiadających co najmniej jedno zamówienie. Dodałem również unikalny indeks na Customer_ID, co przyspiesza operacje odświeżania widoku i umożliwia szybkie wyszukiwanie konkretnych klientów.

W kwestii kompresji zdecydowałem się na zastosowanie EXTENDED storage dla kolumny Customer_Name. Jest to szczególnie efektywne dla długich wartości tekstowych, które często się powtarzają - w systemach zamówień często mamy wielu klientów o tych samych nazwiskach czy podobnych nazwach firm. 

Partycjonowanie zaimplementowałem na tabeli Orders, dzieląc ją według dat kwartałami. To rozwiązanie jest szczególnie użyteczne w systemach gdzie dane historyczne są często analizowane, ale rzadko modyfikowane. Dodatkowo stworzyłem funkcję automatycznie generującą partycje na kolejny kwartał, co ułatwia zarządzanie rosnącą bazą danych.

Całość rozwiązania została zaprojektowana z myślą o wydajności systemu przy dużej ilości danych oraz łatwości zarządzania w długim okresie.