## HomeFinance

### Problem
Użytkownicy tracą kontrolę nad realnym stanem swojego majątku, ponieważ ich pieniądze, inwestycje i długi są rozproszone w wielu nieskomunikowanych aplikacjach bankowych, fintechach i u brokerów. Ręczne agregowanie tych danych w Excelu jest czasochłonne, a brak jednej bazy danych uniemożliwia całościową, inteligentną optymalizację finansów (np. decyzji: inwestować czy nadpłacać kredyt).

### Najmniejszy zestaw funkcjonalności (MVP)
Zbuduj to w pierwszej kolejności, aby potwierdzić, że aplikacja działa i wnosi wartość:

- Architektura Webowa: Responsywna aplikacja dostępna przez przeglądarkę (desktop i mobile).+
- System importu plików CSV: Manualne wgrywanie wyciągów z 2-3 najpopularniejszych banków/fintechów (np. mBank, Revolut) oraz formatów jednego brokera (np. XTB).
- Kategoryzacja wydatków: Podstawowy silnik (np. oparty na słowach kluczowych w opisie transakcji), który przypisuje wydatki do głównych kategorii (Jedzenie, Mieszkanie, Transport).
- Moduł zadłużenia: Prosty formularz do ręcznego wprowadzenia rat kredytów i harmonogramu spłat.
- Podstawowa historia i bilans: Wykres zmian majątku w czasie na podstawie zaimportowanych danych historycznych.
- Agent AI ds. Doradztwa (Analiza kontekstowa): Agent, który otrzymuje zagregowane dane o majątku i uruchamia analizę scenariuszową na bazie dostarczonych przez Ciebie logik (np. porównanie stopy zwrotu z inwestycji z kosztu kredytu w skali 2 miesięcy) i generuje spersonalizowany, krótki komunikat dla użytkownika.
- Pulpit finansowy: Jeden czytelny wykres i podsumowanie pokazujące aktualny stan kont, wartość inwestycji i sumę długów oraz boks z "Rekomendacją AI".

### Co NIE wchodzi w zakres MVP (Zostaw na później)
- Automatyczne pobieranie kursów aktywów live: Integracja z API giełd kryptowalutowych czy rynków tradycyjnych (ceny aktywów w MVP mogą być wpisywane ręcznie lub bazować na wartości z pliku CSV w momencie importu)
- Budżetowanie i cele oszczędnościowe: Planowanie limitów wydatków na dany miesiąc.
- Wielowalutowość: Pełne przeliczanie i śledzenie zysków/strat kursowych w czasie rzeczywistym.
- Zaawansowane promptowanie przez użytkownika: Brak czatu z AI – agent działa w tle i pluje gotowym wynikiem na dashboard.

### Kryteria sukcesu
Aplikacja odniosła sukces w fazie MVP, jeśli:
- Skuteczność importu: Użytkownik jest w stanie zaimportować pliki CSV z wybranych instytucji bez błędów w parsowaniu kwot i dat w 95% przypadków.
- Skuteczność Agenta Kategoryzacji: Agent AI poprawnie przypisuje minimum 85% transakcji do właściwych kategorii przy pierwszym imporcie, bez pomocy użytkownika.
- Trafność i bezpieczeństwo rekomendacji: Agent AI w 100% przypadków generuje rekomendacje doradcze zgodnie z zaimplementowaną logiką biznesową (np. poprawnie wychwytuje moment, gdy zysk z lokaty/giełdy jest niższy niż koszt kredytu i bezbłędnie sugeruje nadpłatę).
