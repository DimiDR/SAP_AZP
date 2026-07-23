# AZP-Tool – Logik & Service (ABAP RAP) · Dokumentation

> Beschreibt die **Logik in SAP**: die zentrale ABAP-Klasse `ZCL_ZAZP_VALIDATION`, das **RAP-Behavior**
> für die Fiori-UI und die **SM30-Validierungs-Events** für SAP GUI. **Beide Oberflächen rufen
> dieselbe Logik** → keine Doppelpflege. Baut auf [`AZP-CDS-Datenmodell.md`](AZP-CDS-Datenmodell.md) auf.
> Stand: 2026-07-23

---

## 1. Überblick

```
                 ZCL_ZAZP_VALIDATION   (Plausibilität – die eine Regelquelle)
                 ZCL_ZAZP_GENERATION   (Monatssimulation, read-only)
                 ZCL_ZAZP_PERSIST      (Schreiben Standardtabellen + Transport)
                        ▲                                   ▲
        ┌───────────────┘                                   └──────────────┐
   SAP GUI                                                          RAP-Behavior
   SM30-Events (V_T508A/V_T550A/…) · Transaktion ZAZP01             ZBP_I_ZAZP_* 
   → volle Prüfung, ohne Fiori                                      → OData → Fiori Elements
```

Die Klassen sind **UI-unabhängig**: SM30-Events und RAP-Behavior rufen dieselben Methoden.

---

## 2. Zentrale Logik-Klasse `ZCL_ZAZP_VALIDATION`

Interface `ZIF_ZAZP_VALIDATION` (damit sowohl RAP als auch SM30 dagegen programmieren):

```abap
interface zif_zazp_validation public.
  types:
    begin of ty_message,
      severity type symsgty,     " 'E' | 'W' | 'I'
      field    type string,      " betroffenes Feld/Objekt
      text     type string,
    end of ty_message,
    ty_messages type standard table of ty_message with empty key.

  " Regel inkl. Wochenmuster/Tages-/Pausenplan prüfen (Vollprüfung)
  methods validate_rule
    importing rule_id       type t508a-schkz
              dws_grouping  type t508a-motpr
    returning value(messages) type ty_messages.

  " Einzelprüfungen (für SM30-Feld-/Satzebene wiederverwendbar)
  methods validate_daily
    importing dws type ty_daily     returning value(messages) type ty_messages.
  methods validate_break
    importing brk type ty_break     returning value(messages) type ty_messages.
endinterface.
```

`ZCL_ZAZP_VALIDATION` implementiert das Interface und kapselt die Regeln aus §4.

Zusätzlich (seit 2026-07-19):

```abap
TYPES: BEGIN OF ty_rule_ctx,
         rule    TYPE t508a,
         weeks   TYPE STANDARD TABLE OF t551a WITH EMPTY KEY,
         dailies TYPE STANDARD TABLE OF t550a WITH EMPTY KEY,
         breaks  TYPE STANDARD TABLE OF t550p WITH EMPTY KEY,
       END OF ty_rule_ctx.

METHODS validate_rule_ctx
  IMPORTING ctx TYPE ty_rule_ctx
  RETURNING VALUE(messages) TYPE ty_messages.
```

- `validate_rule` lädt aus der DB und delegiert an `validate_rule_ctx`.
- `ZCL_ZAZP_PERSIST=>save_rule` und SM30 prüfen den **Payload/Context**, nicht den alten DB-Stand.
- RAP-Validierungen: `valWeekSum` → Context; `valTimeframe` → `validate_daily` je referenziertem T550A; `valBreaks` → `validate_break` je T550P.

---

## 3. RAP-Behavior (optionale Fiori-UI)

Behavior-Definition für `ZI_ZAZP_WorkScheduleRule` – **managed with unmanaged save** (RAP führt
Draft/Locking/Validierungen; das Speichern schreibt über `ZCL_ZAZP_PERSIST` in die Standardtabellen und
zeichnet nativ auf einem Transportauftrag auf):

```abap
managed with unmanaged save implementation in class zbp_i_zazp_workschedulerule unique;
strict ( 2 );

define behavior for ZI_ZAZP_WorkScheduleRule alias Rule
draft table zazp_d_rule
lock master
authorization master ( instance )
{
  create; update; delete;
  draft action Edit;
  draft action Activate;
  draft determine action Prepare { validation valWeekSum; validation valTimeframe; }

  // Determinations (Ableitungen)
  determination computeAverages on modify { field PeriodId; }

  // Validierungen – delegieren an ZCL_ZAZP_VALIDATION
  validation valWeekSum   on save { create; update; field PeriodId; }
  validation valTimeframe on save { create; update; }
  validation valBreaks    on save { create; update; }

  // Aktionen
  action ( features : instance ) copyAsTemplate
         parameter ZA_ZAZP_CopyParams   result [1] $self;
  action simulateMonth
         parameter ZA_ZAZP_SimParams    result [0..*] ZI_ZAZP_SimDay;

  // Transport (statisch)
  static action listTransportRequests
         result [0..*] ZI_ZAZP_SimDay;
  static action createTransportRequest
         parameter ZA_ZAZP_TransportParams result [1] ZI_ZAZP_SimDay;
  static action setPreferredTransport
         parameter ZA_ZAZP_TransportParams;

  // Mitarbeiterzuordnung IT0007 (statisch, Weg B)
  static action readEmployeeAssignment
         parameter ZA_ZAZP_MonthParams result [1] ZI_ZAZP_SimDay;
  static action assignEmployee
         parameter ZA_ZAZP_MonthParams result [1] ZI_ZAZP_SimDay;

  association _Weeks       { create; with draft; }
  association _DailySchedules { create; with draft; }
  association _BreakSchedules { create; with draft; }
}
```

- **Validierungen** rufen `ZCL_ZAZP_VALIDATION` (kein Regel-Code im Behavior selbst).
- **`saver`** (unmanaged save) delegiert an `ZCL_ZAZP_PERSIST` → schreibt `T508A/T551A/T550A/T550P` und
  Transportauszeichnung (nativ, → [`AZP-Transport-Service-Spezifikation.md`](AZP-Transport-Service-Spezifikation.md)).
- **Draft** nur für Fiori; Aktivdaten bleiben in den Standardtabellen.
- `ZA_ZAZP_TransportParams` nur Transportfelder (`TransportRequest` / `TransportDescription`).
- `ZA_ZAZP_SimParams` nur Jahr/Monat für `simulateMonth`.
- `ZA_ZAZP_MonthParams` / `ZI_ZAZP_SimDay` für Zuordnung
  (Pernr, RuleId, ValidFrom/To, EmploymentPct, WeeklyHours; Ergebnis zusätzlich Success, MessageText, Transport-Echo).

---

## 4. Validierungsregeln (`ZCL_ZAZP_VALIDATION`)

| Regel | Schweregrad |
|---|---|
| Jeder in `WeekPattern` referenzierte Tagesplan-Code existiert als `DailyWorkSchedule` | E |
| Wochensumme (Σ Tages-Sollstunden) = Ø-Wochenwert der Regel (`AvgWeekHours`) ± Toleranz | E |
| `WorkStart ≤ CoreStart ≤ CoreEnd ≤ WorkEnd`; Kernzeit ⊆ Normalzeit ⊆ Sollrahmen | E |
| Toleranzen innerhalb des Sollrahmens | W |
| `TargetHours` plausibel zu (WorkEnd − WorkStart − unbezahlte Pausen) | W |
| Referenzierter Pausenplan existiert; Pausen liegen im Arbeitszeitrahmen | E |
| `ValidFrom ≤ ValidTo`; keine Überlappung gleicher Schlüssel | E |
| `AvgWeekHours` im Plausibilitätsbereich (z. B. 20–48 h, konfigurierbar) | W |
| Frei-Tag = Tagesplan-Code mit 0 Std. | W |

Ergebnis als `ty_messages`; ein **E** verhindert das Speichern (RAP-`reported`/`failed` bzw. SM30-Abbruch).

---

## 5. Monatssimulation (`ZCL_ZAZP_GENERATION`)

Bildet die SAP-Generierung (`RPTKAL00` → `T552A`) **read-only** nach – ohne Fortschreibung:

1. Kalendertage des Monats; Periodenmuster (`PeriodId` → `WeekPattern`) über die Tage ausrollen
   (Wochennummern-Rotation).
2. Feiertage aus `HolidayCalendarId` anwenden → Tagestyp überschreibt den Tagesplan.
3. Je Tag Tagesplan + Sollstunden, Monatssumme; Vergleich zum Ø-Monatswert der Regel.

Aufruf aus RAP-Action `simulateMonth` **und** (optional) aus SAP GUI (Transaktion `ZAZP01`) – dieselbe
Klasse. Wo möglich werden die Standard-Generierungsbausteine hinter `RPTKAL00` im Simulationsmodus genutzt.

---

## 6. SAP GUI – SM30-Validierungs-Events

Damit SAP GUI **ohne Fiori** dieselben Prüfungen hat, werden an den Pflege-Views die
Table-Maintenance-Events implementiert und rufen `ZCL_ZAZP_VALIDATION`:

| View (SM30) | Standardtabelle | Event → Aufruf |
|---|---|---|
| `V_T508A` | T508A | Event 01 „Vor dem Sichern" → `validate_rule` |
| `V_T550A` | T550A | Event 01 → `validate_daily` |
| `V_T550P` | T550P | Event 01 → `validate_break` |
| `V_T551A` | T551A | Event 01 → `validate_rule` (Wochensumme) |

Optionale **Transaktion `ZAZP01`** als geführter Einstieg (Sammelpflege einer Regel inkl. Simulation),
die dieselben Klassen nutzt. Der Transport läuft über die SM30-Standard-Auftragsabfrage (nativ).

---

## 7. Weg B – Mitarbeiterzuordnung (IT0007)

Separat von der AZP-Definition; **Stammdaten, ohne Transport**:

| Schicht | Objekt / Einstieg |
|---|---|
| Logik | `ZCL_ZAZP_ASSIGNMENT` → `read_current` / `assign_rule` via `HR_MAINTAIN_MASTERDATA` (INS/MOD, Infotyp 0007, Feld `SCHKZ`) |
| RAP | Statische Actions `readEmployeeAssignment` / `assignEmployee` (Parameter in `ZA_ZAZP_MonthParams`, Ergebnis in `ZI_ZAZP_SimDay`) |
| Fiori | Button **„Mitarbeiter zuordnen“** auf List Report + Object Page → Dialog `AssignmentDialog` (`ext/lib/Assignment.js`) |
| GUI | klassisch `PA30`/`PA40`; Smoke-Read im Report `ZAZP_E2E` |

Berechtigung: `P_ORGIN` (Schreiben). Ohne Recht → sauberer Fehler, kein Datenschreiben.

---

## 8. Berechtigungen

| Ebene | Objekt |
|---|---|
| Customizing-Pflege | `S_TABU_DIS` / `S_TABU_NAM` (Tabellen T508A/…) |
| Transport | `S_TRANSPRT` |
| IT0007 (Weg B) | HR-Berechtigungen `P_ORGIN` / `P_PERNR` |
| RAP/Fiori | DCL-Access-Control `ZI_ZAZP_*` + Fiori-Kachel-Rolle |

---

## 9. Nächste Schritte

1. ~~Logik-Klassen / Persist / Generation / Assignment~~ → erledigt.
2. ~~RAP Actions: copy / simulate / Transport / IT0007-Zuordnung~~ → erledigt (Spiegel: `sap/`).
3. Manuell: SE91-Texte `ZAZP`, SE54-Events, FUGR `ZAZP_SM30` in SE80 aktivieren.
4. Web-UI-Kern (Draft, Extensions, Binding) erledigt — siehe [AZP-OData-V4-Service.md](AZP-OData-V4-Service.md) und [AZP-Frontend-Dokumentation.md](../fachlich/AZP-Frontend-Dokumentation.md).
5. Noch offen: PFCG-Rollen, FLP-Kachel, Service-Republish im Customizing-Client, MSAG-Texte.
