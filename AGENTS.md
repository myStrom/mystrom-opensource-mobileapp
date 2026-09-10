# Reguły implementacji i weryfikacji

1. Przed zmianą wypisz krótkie, sprawdzalne kryteria akceptacji.
   Każde wymaganie użytkownika musi mieć odpowiadający mu
   oczekiwany rezultat i sposób sprawdzenia.

2. Prześledź cały przepływ zmienianego zachowania:
   interfejs → logika → żądanie API lub zapis → odczyt → interfejs.
   Wyszukaj wszystkie miejsca korzystające z tej samej funkcji.
   Przy kolorach uwzględnij strip, bulb, harmonogram i action URL.

3. Oczekiwany wynik wyprowadzaj z wymagania lub kontraktu API.
   Nie uznawaj istniejącego kodu, komentarza ani atrapy serwera
   za samodzielny dowód poprawnego zachowania urządzenia.

4. Test musi wykrywać brak wykonania operacji i błędny wynik.
   Przy sterowaniu urządzeniem sprawdzaj nowe żądanie, metodę,
   endpoint, parametry i stan końcowy. Stan początkowy nie może
   sam spełniać wszystkich warunków zaliczenia.

5. Przy naprawie błędu dodaj test regresji, gdy jest wykonalny.
   Potwierdź, że wykrywa pierwotny błąd, najlepiej przez wynik
   przed poprawką i po niej. Nie osłabiaj asercji tylko po to,
   aby test przeszedł.

6. Dla konwersji sprawdzaj oba kierunki oraz konkretne wyniki:
   minimum, maksimum, wartości spoza zakresu, przejście przez
   północ i granicę tygodnia. Sam test konwersji tam i z powrotem
   nie wystarcza — dwa błędy mogą się wzajemnie znosić.

7. Dla zmienianych operacji asynchronicznych sprawdź sukces
   oraz istotne błędy, np. timeout lub odrzucenie przez urządzenie.
   Interfejs nie może raportować sukcesu po nieudanej operacji.
   Zapis sprawdzaj przez ponowny odczyt lub otwarcie ekranu.

8. Nie zastępuj błędnych danych arbitralną poprawną wartością
   bez uzasadnienia w wymaganiach. Jawnie określ, czy dane mają
   zostać odrzucone, ograniczone do zakresu czy zastąpione.

9. Uruchom flutter analyze i testy właściwe dla zmiany.
   Testy integracyjne Windows uruchamiaj osobno dla każdego pliku.
   Rozróżniaj testy na atrapie od testów na fizycznym urządzeniu.
   Placeholder, pominięty test i brak danych nie potwierdzają funkcji.

10. Wyniki sprawdzeń dotyczą wersji kodu, na której je wykonano.
    Po kolejnych zmianach ponów dotknięte sprawdzenia.
    Przy równoległej pracy sprawdź, czy testowane pliki nie zmieniły
    się w trakcie weryfikacji. Nie nadpisuj cudzych zmian.

11. W raporcie końcowym podaj:
    - spełnione kryteria i dowody;
    - wykonane komendy oraz ich wyniki;
    - niewykonane sprawdzenia i przyczyny;
    - pozostałe błędy lub ograniczenia.
    „Zaimplementowane, niesprawdzone” jest osobnym statusem.
    Nie pisz „wszystko działa”, jeśli sprawdzano tylko część.