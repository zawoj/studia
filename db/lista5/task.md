Zakres:  

Wybierz zbiór (lub zbiory) danych, który wykorzystasz podczas projektu i uzasadnij wybór. 

 Zdecyduj w jakich kolekcjach będą się znajdować i uzasadnij wybór. Zmodyfikuj dane tak, żeby skorzystać zarówno z dokumentów zagnieżdżonych, jak i referencji do powiązania danych ze sobą. Przedstaw różnice i pokaż w jaki sposób można skorzystać z obu rodzajów (praktycznie, w postaci złożonych zapytań). 

Przygotuj potrzebne elementy, żeby obsłużyć logikę biznesową po stronie bazy danych – funkcje do dodawania i modyfikacji elementów w kolekcji, sekwencje do autoinkrementacji, agregacje, itd. Liczy się zarówno złożoność, jak i kompletność obsłużenia logiki biznesowej. 

Stwórz indeksy na odpowiednich polach kolekcji. Przedstaw na praktycznych przykładach wydajność zapytań pokrytych różną liczbą indeksów. 

Pokaż na praktycznym przykładzie jak działa mechanizm transakcyjny w używanej wersji MongoDB. 

Wybierz, zaprezentuj w praktyce i oceń do trzech zaawansowanych funkcjonalności MongoDB, które pasują do wybranego projektu (np. obsługa Map/Reduce, capped collections, GridFS, zapytania geoprzestrzenne, przetwarzanie grafów, obsługa dużych danych tekstowych, szyfrowanie, zapytania ad hoc, load balancing, …). 

Co przesyłamy?

Plik pdf z wnioskami. 

Krótko i treściwie (max ½ strony A4) przedstaw wnioski dotyczące zastosowania bazy dokumentowej dla wybranego problemu i praktycznych różnic, jakie są w stosunku jakbyśmy mieli zamiast tego skorzystać z bazy relacyjnej.  


Wnioski na podstawie zadania i doświadczenia mam następujące. Dokumentow bazy danych mają kilka relanych zastsowań, gdy tworzymy MVP lub nasze dane trudno otypować oraz jeszcze gdy filtrujemy geolokalizacyjnie. Każdy inny przypadek nie ma długo trwałych korzyści z wykorzystania dokumentowej bazy danych. Ale dodając jeszcze komentarz dlaczego do tych trzech rzeczy się to nadaje.

MVP
Gdy nie znamy jeszcze dokłądnie potrzebnej struktury danych w projeckie bądź może sie ona jeszcze cześto zmienia

Trudne do otyupowania dane.
Miałem klienta dla którgo budowałem dedykowane rozwiązanie CMSowe (page builder). W takim przypadku dokumentowa baza danych sprawdza się idelanie. Bo każda podstrona ma zupełnie inną strukture. Prawdą też, jest, że można takie rzeczy zaprogramować w relacyjnej bazie dancyh (WordPress) ale albo bardzo długo przemyślimy bazę danych by mogła być dynamiczna, albo korzystamy z typów JSON. Tylko jaki jest sens zapisaywania w JSON skoro mamy cały "system" bazodanowy obsługujący ten rodzaj "plików".

Filtracja Geolokalizacyjna
Oczywiście, że da się to zrobić rozsądnie w bazach relacyjnych. Ale trzeba tutaj oddać zasługi MonogDB gdyż działa to bardzo dobrze jest to łatwe w wykorzystaniu dla programistów oraz spełnia założenia bizensowe w prkatycznie każdym przypadku. Miałem już 3 projekty gdy z tego powodu wybrana została baza MonogoDB do produkcyjnego wdrożenia.