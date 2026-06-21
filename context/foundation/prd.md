---
project: "HomeFinance"
version: 1
status: draft
created: 2026-06-14
context_type: greenfield
product_type: web-app
target_scale:
  users: small
  qps: low
  data_volume: small
timeline_budget:
  mvp_weeks: 6
  hard_deadline: null
  after_hours_only: true
---

# HomeFinance — Product Requirements Document

## Vision & Problem Statement

Pieniądze, inwestycje i długi użytkownika są rozproszone w wielu niekomunikujących się
aplikacjach bankowych, fintechach i u brokerów. Bez jednej bazy danych nie da się zobaczyć
realnego stanu majątku ani podjąć dobrych decyzji optymalizacyjnych (np. inwestować czy
nadpłacać kredyt). Dziś jedyną drogą jest ręczna agregacja wyciągów w Excelu — czasochłonna,
błędogenna i tak nie dająca pełnego, aktualnego obrazu. Ból ma cztery wymiary jednocześnie:
dane uwięzione w silosach, paraliż decyzyjny, mozół ręcznej pracy i brak inteligentnej rady.

Istniejące narzędzia (agregatory, budżetówki) zatrzymują się na *pokazaniu* danych.
HomeFinance dokłada warstwę, której one nie mają — aktywnego doradcę, który dostaje
zagregowany obraz całego majątku i sam, w tle, uruchamia analizę scenariuszową na bazie
zdefiniowanej logiki biznesowej (np. porównanie stopy zwrotu z inwestycji z kosztem kredytu),
po czym wystawia użytkownikowi gotową, spersonalizowaną rekomendację.

## User & Persona

Główna persona: **właściciel rozproszonych finansów** — pojedynczy zaawansowany użytkownik
(Ty, ewentualnie Ty + rodzina/gospodarstwo domowe), który ma wiele kont, inwestycje i kredyty
naraz i dziś sam próbuje ogarnąć całość w Excelu. Sięga po produkt w momencie, gdy chce
zobaczyć realny stan majątku albo podjąć decyzję typu „inwestować czy nadpłacać".
Prywatne narzędzie w duchu „scratch your own itch", nie produkt masowy w MVP.

## Success Criteria

### Primary
- Najmniejszy przepływ end-to-end działa: użytkownik importuje CSV → transakcje są
  skategoryzowane → pulpit pokazuje zagregowany majątek (konta + inwestycje − długi)
  z wykresem zmian w czasie → doradca wystawia rekomendację. Powodzenie tego przepływu =
  produkt zadziałał.
- Import CSV bez błędów parsowania kwot i dat w **≥ 95%** przypadków.
- Kategoryzacja poprawnie przypisuje **≥ 85%** transakcji przy pierwszym imporcie,
  bez ręcznej korekty użytkownika.
- Doradca w **100%** przypadków generuje rekomendację zgodną z zaimplementowaną logiką
  biznesową (np. poprawnie wychwytuje moment, gdy zysk z inwestycji jest niższy niż koszt
  kredytu, i bezbłędnie sugeruje nadpłatę).

### Secondary
- Czytelny wykres zmian majątku w czasie, który sam w sobie daje użytkownikowi poczucie
  kontroli — efekt „wow" niezależny od rekomendacji. Miły dodatek, niewystarczający sam
  w sobie do uznania MVP za sukces.

### Guardrails
- **Poprawność kwot i bilansu**: żadnego cichego przekłamania liczb — błąd w sumie majątku
  jest gorszy niż brak funkcji. Zaufanie do liczb jest fundamentem; jego utrata to regresja
  nawet przy spełnionym Primary.
- **Prywatność danych finansowych** (patrz Access Control): dane nie wyciekają, użytkownik
  ma pełną kontrolę, brak open-bankingu.

## User Stories

### US-01: Użytkownik widzi realny stan majątku po imporcie

- **Given** zalogowany użytkownik bez wcześniejszych danych
- **When** zaimportuje wyciąg CSV z banku i (opcjonalnie) od brokera, wprowadzi swoje kredyty
- **Then** na pulpicie widzi zagregowany majątek (konta + inwestycje − długi), wykres zmian
  w czasie oraz boks z rekomendacją

#### Acceptance Criteria
- Import CSV parsuje kwoty i daty bez błędów w ≥ 95% przypadków
- Transakcje są automatycznie skategoryzowane (≥ 85% trafnie przy pierwszym imporcie)
- Bilans (suma majątku) jest policzony poprawnie — żadnego cichego przekłamania liczb
- Pusty stan (brak importu) pokazuje czytelny ekran zachęcający do pierwszego importu,
  nie pusty/zepsuty pulpit

### US-02: Użytkownik dostaje rekomendację zgodną z logiką

- **Given** użytkownik z zagregowanymi danymi: aktywne inwestycje oraz kredyt z kosztem
- **When** doradca uruchamia analizę scenariuszową w tle
- **Then** użytkownik widzi krótką, spersonalizowaną rekomendację (np. „nadpłać kredyt")

#### Acceptance Criteria
- Gdy oczekiwany zysk z inwestycji jest niższy niż koszt kredytu, rekomendacja w 100%
  przypadków sugeruje nadpłatę (i odwrotnie)
- Rekomendacja nigdy nie jest sprzeczna z danymi ani z zaimplementowaną logiką biznesową
- Brak czatu / promptowania — wynik pojawia się gotowy na pulpicie

## Functional Requirements

### Uwierzytelnianie
- FR-001: Użytkownik może założyć konto i zalogować się. Priority: must-have
  > Socrates: Rozważony kontrargument: „profil lokalny byłby prostszy/bardziej prywatny".
  > Rozstrzygnięcie: zostaje — logowanie obsługuje desktop+mobile i jest podstawą kontroli
  > dostępu; prywatność adresowana guardrailem, nie rezygnacją z konta.

### Import danych
- FR-002: Użytkownik może zaimportować wyciąg CSV z banku/fintechu (np. mBank, Revolut). Priority: must-have
  > Socrates: Rozważony kontrargument: „wiele banków = bagno formatów; zacznij od jednego".
  > Rozstrzygnięcie: zostaje must-have z 2-3 bankami — koszt parserów świadomie zaakceptowany
  > w ramach 6-tyg. timeline'u; import jest rdzeniem wartości.
- FR-003: Użytkownik może zaimportować wyciąg CSV od brokera (np. XTB). Priority: nice-to-have
  > Socrates: Rozważony kontrargument: „drugi parser — odłóż na v2; FR-005 pokrywa inwestycje".
  > Rozstrzygnięcie: ZMIENIONO na nice-to-have (v2). W v1 wartość inwestycji wpisywana ręcznie
  > (FR-005); import brokera wraca w v2.

### Kategoryzacja
- FR-004: Użytkownik dostaje zaimportowane transakcje automatycznie skategoryzowane do głównych kategorii (Jedzenie, Mieszkanie, Transport). Priority: must-have
  > Socrates: Rozważony kontrargument: „85% przy braku korekty psuje rozbicie na kategorie".
  > Rozstrzygnięcie: zostaje — 85% to świadomie zaakceptowany próg; kategoryzacja nie wpływa
  > na poprawność sumy majątku (guardrail), tylko na rozbicie wydatków.

### Inwestycje
- FR-005: Użytkownik może ręcznie wpisać/zaktualizować wartość aktywów; dla importu brokera wartość brana jest z momentu importu CSV. Priority: must-have
  > Socrates: Rozważony kontrargument: „ręczne dane się dezaktualizują → bilans nieaktualny".
  > Rozstrzygnięcie: zostaje — bez cen live to jedyna droga do wartości inwestycji w v1;
  > aktualność jest odpowiedzialnością użytkownika (świadomie poza zakresem cen live).

### Zadłużenie
- FR-006: Użytkownik może ręcznie wprowadzić kredyty wraz z harmonogramem spłat. Priority: must-have
  > Socrates: Rozważony kontrargument: „harmonogram to przerost; wystarczy suma długu".
  > Rozstrzygnięcie: zostaje — koszt kredytu wyliczany z harmonogramu jest wprost wejściem
  > rekomendacji „inwestować vs nadpłacać"; to rdzeń logiki, nie ozdoba.

### Majątek i historia
- FR-007: Użytkownik widzi wykres zmian majątku w czasie na bazie zaimportowanych danych historycznych. Priority: must-have
  > Socrates: Rozważony kontrargument: „przy jednym imporcie historia jest cienka".
  > Rozstrzygnięcie: zostaje — to zadeklarowane Secondary 'wow'; wykres buduje się z danych
  > historycznych zawartych w wyciągach, więc nawet jeden import daje trend.

### Pulpit
- FR-008: Użytkownik widzi pulpit z podsumowaniem: stan kont, wartość inwestycji i suma długów. Priority: must-have
  > Socrates: Rozważony kontrargument: „same liczby bez wykresu wystarczą na v1".
  > Rozstrzygnięcie: zostaje — zagregowane podsumowanie to sedno produktu; jeden obraz całości.
- FR-009: Użytkownik widzi na pulpicie boks „Rekomendacja". Priority: must-have
  > Socrates: Rozważony kontrargument: „boks bez zaufanej rekomendacji to pusty UI".
  > Rozstrzygnięcie: zostaje — sprzężony z FR-010 i guardrailem 'rekomendacja nie wprowadza
  > w błąd'; to kanał, którym insight dociera do użytkownika.

### Doradztwo
- FR-010: Użytkownik otrzymuje rekomendację generowaną w tle na bazie zagregowanego majątku i zdefiniowanej logiki biznesowej. Priority: must-have
  > Socrates: Rozważony kontrargument: „najdroższy/najryzykowniejszy kawałek — odłóż na v2".
  > Rozstrzygnięcie: zostaje — aktywna rada to cały wyróżnik produktu; bez niej HomeFinance
  > jest kolejnym agregatorem. Ryzyko akceptowane jako rdzeń MVP.

## Non-Functional Requirements

- Zaimportowane kwoty i wyliczony bilans majątku zgadzają się ze źródłowymi wyciągami
  co do grosza — żadnego cichego zaokrąglania ani przekłamania sum.
- Rekomendacja doradcza jest w 100% zgodna z zaimplementowaną logiką biznesową względem
  danych, na których działa (brak rady sprzecznej z drabiną priorytetów).
- Kluczowe liczby i rekomendacja na pulpicie są odczytywalne bez tłumaczenia: czytelny
  kontrast, rozmiar i jednoznaczne etykiety, tak by użytkownik rozumiał stan majątku na
  pierwszy rzut oka.
- Dane finansowe pozostają pod kontrolą użytkownika i nie opuszczają produktu poza jego
  wiedzą (eksport i trwałe usunięcie możliwe; brak open-bankingu) — patrz Access Control.

## Business Logic

HomeFinance, na podstawie zagregowanego obrazu majątku (salda kont, wartości inwestycji,
warunki długów i przepływy), wskazuje użytkownikowi optymalny następny ruch finansowy według
drabiny priorytetów — najpierw zapewnienie poduszki płynności, potem spłata najdroższego
długu, następnie reakcja na nadwyżkę lub deficyt budżetowy, a na końcu alokacja wolnej
gotówki (oszczędzać, inwestować czy nadpłacić kredyt).

Reguła konsumuje wejścia widoczne dla użytkownika: bieżące salda kont, wartość inwestycji
(wpisaną ręcznie lub z momentu importu), warunki każdego kredytu (kwota, koszt/oprocentowanie,
harmonogram spłat) oraz miesięczne przepływy wynikające z zaimportowanych i skategoryzowanych
transakcji (wpływy vs wydatki). Z tych wejść reguła wylicza, na którym szczeblu drabiny
priorytetów użytkownik się znajduje, i wybiera jeden najważniejszy ruch.

Wyjściem jest jedna krótka, spersonalizowana rekomendacja wskazująca ten ruch (np. „odłóż
nadwyżkę na poduszkę", „nadpłać najdroższy kredyt", „ulokuj nadwyżkę w inwestycję").
Użytkownik napotyka ją jako gotowy komunikat w boksie „Rekomendacja" na pulpicie —
generowany w tle, bez czatu i bez ręcznego promptowania.

## Access Control

Użytkownik wchodzi przez **logowanie do konta** (uwierzytelnienie wymagane do dostępu do
jakichkolwiek danych finansowych). Model jest **płaski**: jedno konto = jeden zestaw danych,
każdy użytkownik widzi wyłącznie własne dane majątkowe. Brak ról, brak współdzielenia,
brak gospodarstwa wieloosobowego w MVP. Nieuwierzytelniony użytkownik nie ma dostępu do
żadnej trasy z danymi.

Prywatność jest traktowana jako **guardrail produktu**, nie tylko cecha: dane finansowe są
pod pełną kontrolą użytkownika (eksport/usunięcie), bez integracji z open-bankingiem
(wyłącznie import plików CSV). Konkretny mechanizm uwierzytelniania i szyfrowania jest
decyzją downstream (wybór stacku), nie PRD.

## Non-Goals

- **Brak kursów aktywów live / integracji z API giełd** — ceny aktywów wpisywane ręcznie
  lub brane z wartości w pliku CSV w momencie importu; trzyma zakres importu wąsko i unika
  zależności od zewnętrznych źródeł cen.
- **Brak budżetowania i celów oszczędnościowych** — planowanie limitów wydatków to osobny
  moduł na później; MVP skupia się na obrazie majątku i rekomendacji.
- **Brak pełnej wielowalutowości / FX w czasie rzeczywistym** — bez przeliczania i śledzenia
  zysków/strat kursowych na żywo.
- **Brak czatu / zaawansowanego promptowania** — doradca działa w tle i wystawia gotowy
  wynik na pulpit; brak interaktywnej rozmowy w MVP.
- **Brak współdzielenia / wielu użytkowników (single-tenant lock)** — płaski model jednego
  użytkownika z Access Control; brak gospodarstwa wieloosobowego i zaproszeń w MVP.
- **Import CSV od brokera poza zakresem must-have v1** — przeniesiony do nice-to-have/v2
  (FR-003); w v1 wartość inwestycji pokrywa ręczny wpis (FR-005).

## Open Questions

Brak otwartych pytań blokujących na tym etapie. Kontrola jakości w `/10x-shape`
zakończyła się statusem `accepted` (wszystkie elementy obecne, bez luk).

Pozycje odłożone (świadome decyzje zakresowe, nie luki):

1. **Import CSV od brokera (np. XTB)** — zaplanowany na v2; w v1 wartość inwestycji wpisywana
   ręcznie (FR-005). Owner: użytkownik. By: po MVP.
