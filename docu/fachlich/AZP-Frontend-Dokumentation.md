# AZP-Tool – Frontend-Designdokumentation

> UI-Zielbild des AZP-Tools. Das **optionale Eigen-Frontend ist eine Fiori-Elements-UI auf ABAP RAP**.
> Der klassische Desktop-Zugang zu Arbeitszeitplänen ist **SAP GUI (Standard-Transaktionen)** – kein
> Eigenbau. Baut auf [`AZP-SAP-Arbeitszeitplan-Dokumentation.md`](AZP-SAP-Arbeitszeitplan-Dokumentation.md) auf.
> Stand: 2026-07-23

---

## 1. Überblick

Zwei Oberflächen auf **derselben ABAP-Logik** (§5):

| | **Fiori-UI (Fiori Elements auf RAP)** | **SAP GUI (Standard)** |
|---|---|---|
| Rolle | moderne, komfortable Oberfläche | vollwertige Pflege im System |
| Muss gebaut werden? | RAP-Service + Fiori-App (umgesetzt) | nein – `SM30`/`SPRO`, Transaktion `ZAZP01` |
| Pflege über | List Report / Object Page (OData) | SM30-Pflegeviews mit Validierungs-Events |
| Logik | ruft `ZCL_ZAZP_*` | ruft `ZCL_ZAZP_*` (dieselbe) |

Beide sind gleichwertig: **SAP GUI funktioniert voll ohne Fiori**; Fiori ist der Komfort-Zugang.
Schwerpunkt dieses Dokuments ist die Fiori-UI (§3); SAP GUI siehe §4, Logik-Verteilung §5.

### Ist-Stand Fiori (App `azp-workschedulerule`)

| Feature | Status | Ort |
|---|---|---|
| List Report + Object Page + Draft | ✔ | Fiori Elements |
| Kopieren als Vorlage | ✔ | Action `copyAsTemplate` |
| Monatssimulation | ✔ | `ext/lib/SimulateMonth.js` |
| Transport wählen/anlegen | ✔ | `ext/lib/Transport.js` |
| Wochenmuster-Grid Mo–So + Σ | ✔ | Custom Section `WeekPatternGrid` |
| Status-Ampel (Entwurf / Geplant / In SAP / Abgelaufen) | ✔ | CDS `Status` + Custom-Spalte |
| Validierung & Freigabe (Prüfen → Transport → Aktivieren) | ✔ | Custom Section `ValidationPanel` |
| Multi-Select / Massen-Validieren | ✔ | List Report Actions |
| **Mitarbeiter zuordnen (IT0007)** | ✔ | Button + Dialog `Assignment.js` / Actions `readEmployeeAssignment` · `assignEmployee` |

Noch manuell: FLP-Kachel, PFCG-Rollen, MSAG-Texte, App-Deploy / Service-Republish.

---

## 2. Informationsarchitektur (Fiori-UI)

```
Liste aller Arbeitszeitpläne (AZP-ID)
  └─ AZP-Detail
       ├─ Allgemeine Daten     (Regel, Kalender, Gruppierung, Gültigkeit, Ø-Werte)
       ├─ Wochenmuster         (Woche × Mo–So → Tagesplan-Codes)   ← Herzstück
       ├─ Tagesarbeitszeitpläne(Sollzeit, Rahmen, Toleranz, Kernzeit, Pausenplan)
       ├─ Pausenpläne          (feste / dynamische Pausen)
       ├─ Mitarbeiterzuordnung (Infotyp 0007)
       └─ Validierung & Export (Plausibilität, Simulation, SAP-Übergabe inkl. Transport)
```

Zentrale Aktionen: **Anlegen · Kopieren (Template) · Bearbeiten · Löschen · Validieren · Monat
simulieren · In SAP exportieren (Weg A, mit Transportauswahl) · Mitarbeiter zuordnen (Weg B)**.

---

## 3. Fiori-UI (Fiori Elements auf ABAP RAP)

Floorplan: **List Report + Object Page**, annotationsgetrieben. Draft-Handling aus dem Framework.

### 3.1 List Report

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Arbeitszeitpläne                                     [Anlegen]  [⤓ SAP]   │
├─────────────────────────────────────────────────────────────────────────┤
│ AZP-ID [____]  Gruppierung [__]  Kalender [__]  Gültig am [____]  Status[▾]│
│                                                        [Start] [Anpassen] │
├─────────────────────────────────────────────────────────────────────────┤
│ ☐ AZP-ID │ Bezeichnung        │ Ø Woche │ Kalender │ Gültig ab │ Status    │
│ ☐ GLZ38  │ Gleitzeit 38,5h    │ 38,50 h │ 01       │ 01.01.25  │ ● Aktiv   │
│ ☐ TZ232  │ Teilzeit 23,2h     │ 23,20 h │ 01       │ 01.01.25  │ ○ Entwurf │
│ ☐ SCH3W  │ 3-Schicht rollierd │ 37,00 h │ 02       │ 01.04.25  │ ● Aktiv   │
├─────────────────────────────────────────────────────────────────────────┤
│ [Kopieren] [Validieren] [⤓ SAP-Export]         3 von 128 · 1 ausgewählt   │
└─────────────────────────────────────────────────────────────────────────┘
```

- Filterleiste: AZP-ID, Gruppierung (`MOSID`/`ZEITY`), Kalender (`MOFID`), Stichtag, Status.
- Status-Ampel: Aktiv / Entwurf / In SAP übertragen.
- `SAP-Export` auf mehreren markierten Zeilen öffnet den Transport-Dialog (§3.4).

### 3.2 Object Page

```
┌─────────────────────────────────────────────────────────────────────────┐
│ ‹ GLZ38 – Gleitzeit 38,5h                     ● Aktiv   [Bearbeiten][Kopie]│
│  Allgemein · Wochenmuster · Tagespläne · Pausen · Zuordnung · Validierung │
├─────────────────────────────────────────────────────────────────────────┤
│ ▼ Allgemeine Daten                                                        │
│   AZP-ID    GLZ38            Feiertagskalender  01 – DE Standard           │
│   Bezeichn. Gleitzeit 38,5h  PS-Grp 01   ES-Grp 1                          │
│   Gültig    01.01.2025 – 31.12.9999                                        │
│   Ø Tag 7,70h · Ø Woche 38,50h · Ø Monat 167,00h · Ø Jahr 2004h · Tage/W 5│
├─────────────────────────────────────────────────────────────────────────┤
│ ▼ Wochenmuster (Periodenarbeitszeitplan ZMODN: GLZ)                        │
│  Woche│  Mo  │  Di  │  Mi  │  Do  │  Fr  │  Sa  │  So  │ Σ Woche          │
│   1   │ Z780 │ Z780 │ Z780 │ Z780 │ Z770 │ FREI │ FREI │ 38,50 h          │
│       │ 8,00 │ 8,00 │ 8,00 │ 8,00 │ 6,50 │ 0,00 │ 0,00 │                  │
│  [+ Woche]                                                                │
├─────────────────────────────────────────────────────────────────────────┤
│ ▼ Tagesarbeitszeitpläne                                                   │
│  Code │ Soll  │ Beginn│ Ende │ Normalzeit  │ Kernzeit    │ Pausenplan      │
│  Z780 │ 8,00h │ 07:00 │16:00 │ 09:00–15:00 │ 09:00–15:00 │ P30             │
│  Z770 │ 6,50h │ 07:00 │14:00 │ 09:00–13:00 │ –           │ P15             │
│  FREI │ 0,00h │  –    │  –   │  –          │  –          │  –              │
├─────────────────────────────────────────────────────────────────────────┤
│ ▼ Pausenpläne                                                             │
│  Plan │ Nr │ Von   │ Bis   │ Bezahlt │ Unbezahlt │ Dynamisch nach          │
│  P30  │ 1  │ 12:00 │ 12:30 │  –      │ 0,50h     │  –                      │
│  P15  │ 1  │  –    │  –    │ 0,25h   │  –        │ 6,00h                   │
├─────────────────────────────────────────────────────────────────────────┤
│ ▼ Mitarbeiterzuordnung (Infotyp 0007)                                     │
│  PersNr   │ Name        │ Gültig ab │ Beschäft.% │ Status                  │
│  10023456 │ Muster, Anna│ 01.01.25  │ 100        │ ✓ übertragen            │
│  [+ Zuordnen]                                                             │
├─────────────────────────────────────────────────────────────────────────┤
│ ▼ Validierung & Export                                                    │
│  ✓ Wochensumme 38,50h = Ø-Sollwert   ✓ Tag/Woche konsistent               │
│  ⚠ Fr 6,50h – Kernzeitrahmen prüfen                                       │
│  Transport: DEVK900123 – AZP-Muster Q3/2026                    [ändern]    │
│  [Validieren]  [Monat simulieren]  [⤓ In SAP exportieren]                 │
└─────────────────────────────────────────────────────────────────────────┘
```

Sections = die Modell-Ebenen, alle Untertabellen Inline-Edit im Draft. Das **Wochenmuster-Grid** ist eine
**Custom Section** (eigenes Fragment / UI5-Grid): Zeilen = Wochen, Spalten = Mo–So, Value-Help auf
Tagesplan-Codes, Live-Wochensumme. „FREI" ist ein regulärer Code (0 h), kein Leerwert.

### 3.3 Framework-Verhalten
- **Draft**: Bearbeiten erzeugt Entwurf; *Aktivieren* macht ihn gültig.
- **Value Helps**: Tagesplan (T550A), Pausenplan (T550P), Kalender (`MOFID`), Gruppierungen.
- **Messages**: Validierungsergebnisse als Message-Popover am betroffenen Feld.
- **Export**: gebundene Service-Aktion (kein direktes Table-Write), siehe §3.4.

### 3.4 SAP-Export mit Transportauswahl

AZP-Definitionen sind **Customizing** und werden auf einem **Transportauftrag** aufgezeichnet. Vor dem
Export öffnet sich daher ein Dialog, in dem der Zielauftrag gewählt oder neu angelegt wird:

```
┌ In SAP exportieren ─────────────────────────────────────┐
│ Zielsystem       DEV · Mandant 100                      │
│                                                         │
│ Transportauftrag                                        │
│  (•) Vorhandenen wählen                                 │
│      [ DEVK900123 – AZP-Muster Q3/2026            ▾ ]   │
│      (nur offene, änderbare Customizing-Aufträge)       │
│  ( ) Neuen anlegen                                      │
│      Beschreibung [ ____________________________ ]      │
│                                                         │
│ Zu übertragen: 1 Regel · 1 Wochenmuster ·               │
│                2 Tagespläne · 2 Pausenpläne             │
│                                                         │
│                         [Abbrechen]   [Exportieren]     │
└─────────────────────────────────────────────────────────┘
```

- **Auftragsliste** kommt aus SAP: offene, dem Benutzer zugeordnete, änderbare **Customizing-Aufträge**.
- **Neu anlegen** legt einen Customizing-Auftrag mit eingegebener Beschreibung an.
- Der Export schreibt die Customizing-Sätze und **zeichnet sie auf dem gewählten Auftrag auf** – analog
  zur SAP-GUI-Abfrage „Auftrag" bei `SM30`.
- Der gewählte Auftrag wird in der Object Page (Panel „Validierung & Export") sichtbar gehalten und ist
  über *[ändern]* jederzeit umstellbar.
- Optionale Voreinstellung je Benutzer: „Auftrag merken" / „immer nachfragen".

---

## 4. SAP GUI (Standard-Client) – kein Eigenbau

Der Desktop-Zugang zu Arbeitszeitplänen ist die vorhandene SAP GUI. Das Tool baut sie nicht nach, sondern
**ergänzt/ersetzt** die manuelle Pflege. Zur Orientierung, welche Standard-Transaktion welchem
Tool-Objekt entspricht:

| Tool-Sicht | SAP-GUI-Weg (Standard) |
|---|---|
| Wochenmuster / Tages- / Pausenplan / Regel | `SPRO` → *Personalzeitwirtschaft → Arbeitszeitpläne*, bzw. `SM30`/`SM34` (`V_T551A`, `V_T550A`, `V_T550P`, `V_T508A`) |
| Monatsarbeitszeitplan generieren | Report `RPTKAL00` (→ `T552A`) |
| Mitarbeiterzuordnung (IT0007) | `PA30` / `PA40` |
| Transportauftrag verwalten | `SE01`/`SE09`/`SE10` |

Nach dem Export (Weg A) landen die Sätze im gewählten Transportauftrag und werden im SAP-Standardprozess
(DEV→QAS→PRD) weitertransportiert; Nachbearbeitung/Prüfung erfolgt bei Bedarf in SAP GUI.

---

## 5. Logik-Verteilung (Logik in SAP – ABAP/RAP)

**Entscheidung:** Die AZP-Logik liegt **in SAP (ABAP)** – nicht im UI und nicht in einem externen Tool.
Dadurch funktioniert **SAP GUI voll und ohne Fiori**, und beide Oberflächen teilen **denselben Code**.

### Eine Logik, zwei Oberflächen
```
        ZCL_ZAZP_VALIDATION  (Plausibilität, zentral)
        + Standard RPTKAL00 (Monatsgenerierung)
              ▲                                ▲
   ┌──────────┘                                └──────────┐
 SAP GUI (klassisch)                              RAP-Behavior
 SM30-Events / Transaktion ZAZP01                 ZI_ZAZP_* (Determ./Validations)
 → volle Prüfung, ohne Fiori                      → OData v4 → Fiori Elements (optional)
```

| Logik | Ort (einmalig) | genutzt von |
|---|---|---|
| Plausibilität (Wochensumme, Kernzeit, …) | `ZCL_ZAZP_VALIDATION` | SAP GUI **und** RAP/Fiori |
| Monatsgenerierung | Standard `RPTKAL00` | SAP GUI **und** RAP/Fiori |
| Darstellung / Value-Helps / Wochenmuster-Grid | Fiori Elements bzw. SM30-Dynpro | jeweilige Oberfläche |

### Konsequenzen
- **Keine Divergenz:** eine Regelquelle (ABAP-Klasse), von beiden Oberflächen aufgerufen.
- **SAP GUI eigenständig:** SM30/`SPRO` bzw. Transaktion `ZAZP01` prüfen mit derselben Logik; Fiori ist
  optionaler Komfort-Client, nicht erforderlich.
- **Transport nativ:** Customizing wird beim Speichern dem Auftrag zugeordnet (SM30-Standardabfrage bzw.
  RAP-Transportauszeichnung); kein externer Export.
- **SAP führend:** die Daten leben in den Standardtabellen (T508A/…); Fiori und SAP GUI sind nur Zugänge.

---

## 6. Gemeinsame Komponenten & Design-Prinzipien

- **Wochenmuster-Grid** (Kernkomponente): Zeilen = Wochen (`WONUM`), Spalten = Mo–So (`TPRG1..7`).
  Zelle: Tagesplan-Code + Sollstunden, rechts Live-**Wochensumme**. Value-Help auf T550A; „FREI" = 0 h.
- **Zeitfelder** als `HH:MM`, **Stunden** dezimal mit 2 Nachkommastellen (`38,50 h`).
- **Kopieren als Template**: neuer AZP übernimmt Wochenmuster/Tagespläne/Pausen; AZP-ID und Gültigkeit neu.
- **Validierungsanzeige**: ✓ ok · ⚠ Warnung · ✕ Fehler, verlinkt aufs Feld. Regeln u.a.: Wochensumme =
  Ø-Sollwert, Tag/Woche konsistent, Kernzeit ⊆ Sollrahmen.
- **Transportauswahl** ist Teil jedes Weg-A-Exports (§3.4); ohne gültigen Auftrag ist der Export gesperrt.
- **Status-Kennzeichen**: Entwurf / Aktiv / In SAP übertragen.

---

## 7. Feld-/Spaltenreferenz je Sicht

| Sicht | Angezeigte Felder | Modell (Tabelle) |
|---|---|---|
| Allgemein | AZP-ID, Bezeichnung, Kalender, PS-/ES-Grp, Gültigkeit, Ø Tag/Woche/Monat/Jahr, Tage/W | T508A (+T508S) |
| Wochenmuster | Woche, Mo–So (Tagesplan-Codes), Σ Woche | T551A |
| Tagespläne | Code, Soll, Beginn/Ende, Normalzeit, Toleranz, Kernzeit, Pausenplan | T550A (+T550S) |
| Pausen | Plan, Nr, Von/Bis, Bezahlt/Unbezahlt, dynamisch nach x h | T550P |
| Zuordnung | PersNr, Name, Gültig ab, Beschäft.%, Status | PA0007 (IT0007) |

---

## 8. Zustände & Meldungen

| Zustand | Anzeige | Aktion möglich |
|---|---|---|
| Entwurf | ○ Entwurf | Bearbeiten, Validieren, Aktivieren |
| Aktiv | ● Aktiv | Kopieren, Exportieren, Zuordnen |
| Validierungswarnung | ⚠ am Feld + Panel | Export mit Bestätigung |
| Validierungsfehler | ✕ am Feld + Panel | Export gesperrt |
| Kein Transport gewählt | ⚠ im Export-Dialog | Export gesperrt bis Auftrag gewählt/angelegt |
| Exportiert (Weg A) | ✓ In SAP übertragen (Auftrag DEVK…) | schreibgeschützt bis Neuversion |

---

## 9. Nächste Schritte

1. ~~Fiori-Annotationen / Wochenmuster-Grid / Actions / Transport~~ → erledigt (siehe Ist-Stand §1).
2. ~~Mitarbeiterzuordnung als eigener Dialog~~ → erledigt.
3. App auf S4P **deployen**; Service Binding bei Bedarf republishen.
4. FLP-Kachel + PFCG-Rollen anlegen.
5. Fachbereich-Abnahme (Feldumfang, Pflichtfelder, Value-Helps, IT0007-Write mit Test-PERNR).
6. Optional: Wochenmuster-Grid mit Value-Help auf Tagespläne verfeinern.