# AZP-Tool – Datenmodell (ABAP CDS / RAP) · Dokumentation

> Datenmodell des AZP-Tools **in SAP (ABAP)**. Die Daten bleiben in den **SAP-Standardtabellen** – es gibt
> **keine** parallelen Z-Datentabellen. Das Modell besteht aus **CDS-Views `ZI_ZAZP_*`** über die
> Standardtabellen (Lesen) und **Projektionsviews `ZC_ZAZP_*`** (OData/Fiori). Das Schreiben regelt das
> RAP-Behavior (→ [`AZP-Service-Schicht.md`](AZP-Service-Schicht.md)).
> Grundlage: verifizierte SAP-Tabellen
> ([`AZP-SAP-Arbeitszeitplan-Dokumentation.md`](../fachlich/AZP-SAP-Arbeitszeitplan-Dokumentation.md)).
> Stand: 2026-07-19

---

## 1. Namenskonvention

Paket **`ZAZP_HR_TIME`** (Kunden-Z-Namensraum):

| Ebene | Präfix | Beispiel |
|---|---|---|
| Interface-CDS (über Standardtabellen) | `ZI_ZAZP_` | `ZI_ZAZP_WorkScheduleRule` |
| Projektion / Consumption (OData) | `ZC_ZAZP_` | `ZC_ZAZP_WorkScheduleRule` |
| Wertehilfe-CDS | `ZI_ZAZP_..._VH` | `ZI_ZAZP_HolidayCalendar` |
| Draft-Tabelle (nur Fiori-Draft) | `ZAZP_D_` | `ZAZP_D_RULE` |

> **Kein zweiter Datenspeicher:** Aktivdaten liegen ausschließlich in `T508A/T551A/T550A/T550P/PA0007`.
> `ZAZP_D_*` ist nur die technische Draft-Persistenz der Fiori-Bearbeitung (SAP GUI nutzt keine Drafts).

---

## 2. View-Landschaft

| Interface-View `ZI_ZAZP_*` | Standardtabelle | Text-Assoziation |
|---|---|---|
| `WorkScheduleRule` (root) | `T508A` | `T508S` |
| `WeekPattern` | `T551A` | – |
| `DailyWorkSchedule` | `T550A` | `T550S` |
| `BreakSchedule` | `T550P` | – |
| `EmployeeAssignment` | `PA0007` | – |
| `HolidayCalendar` (Wertehilfe) | Feiertagskalender (SCAL) | – |

```
ZI_ZAZP_WorkScheduleRule
  ├── composition _Weeks           ──▶ ZI_ZAZP_WeekPattern        (T551A)
  ├── composition _DailySchedules  ──▶ ZI_ZAZP_DailyWorkSchedule  (T550A)
  ├── composition _BreakSchedules  ──▶ ZI_ZAZP_BreakSchedule      (T550P)
  ├── association _Assignments     ──▶ ZI_ZAZP_EmployeeAssignment (PA0007)
  └── association _Text            ──▶ ZI_ZAZP_RuleText           (T508S)
```

Composition-Kinder tragen die Parent-Keys (`EsGrouping`…`ValidTo` / `RuleValidTo`) und
`association to parent … as _Rule` — Voraussetzung für Deep Create mit Draft.

---

## 3. CDS – Implementierung

Kanonsiche Quellen unter `sap/ddls/` (aktiv in S4P):

| View | Datei |
|---|---|
| Root | `zi_zazp_workschedulerule.ddls.asddls` |
| Week / Daily / Break | `zi_zazp_weekpattern` / `dailyworkschedule` / `breakschedule` |
| Projektionen `ZC_*` | `zc_zazp_*.ddls.asddls` (Children **ohne** `provider contract`) |

Children joinen `T551A`/`T550A`/`T550P` an `T508A` (`MOTPR`/`ZMODN`), damit die Regel-Keys
im Kind verfügbar sind. Feldabbildung siehe §5.

---

## 4. Projektion für OData/Fiori (`ZC_ZAZP_*`)

```abap
define root view entity ZC_ZAZP_WorkScheduleRule
  provider contract transactional_query
  as projection on ZI_ZAZP_WorkScheduleRule
{
  // … Felder …
  _Weeks           : redirected to composition child ZC_ZAZP_WeekPattern,
  _DailySchedules  : redirected to composition child ZC_ZAZP_DailyWorkSchedule,
  _BreakSchedules  : redirected to composition child ZC_ZAZP_BreakSchedule,
  _Assignments     : redirected to ZC_ZAZP_EmployeeAssignment
}
```

`@UI`-Annotationen liegen in Metadata-Extensions `sap/ddlx/zc_zazp_*.ddlx.asddlxs`
(List Report + Object-Page-Facetten Wochenmuster / Tagespläne / Pausen).

---

## 5. Feld-Mapping CDS ↔ Standardtabelle

| Interface-View | CDS-Feld | Standardfeld | Tabelle |
|---|---|---|---|
| WorkScheduleRule | RuleId · HolidayCalendarId · PsGrouping · EsGrouping · DwsGrouping · PeriodId · ValidFrom/To · Avg* · WorkdaysPerWeek | SCHKZ · MOFID · MOSID · ZEITY · MOTPR · ZMODN · BEGDA/ENDDA · TGSTD/WOSTD/M1STD/JRSTD · WKWDY | T508A (+T508S) |
| WeekPattern | DwsGrouping · PeriodId · WeekNumber · Monday…Sunday | MOTPR · ZMODN · WONUM · TPRG1…TPRG7 | T551A |
| DailyWorkSchedule | DwsGrouping · Code · Variant · TargetHours · WorkStart/End · NormalStart/End · Tol* · CoreStart/End · BreakId | MOTPR · TPROG · VARIA · SOLLZ · SOBEG/SOEND · NOBEG/NOEND · BTBEG/BTEND·ETBEG/ETEND · K1BEG/K1END · PAMOD | T550A (+T550S) |
| BreakSchedule | DwsGrouping · BreakId · SeqNo · StartTime/EndTime · PaidHours/UnpaidHours · AfterHours | MOTPR · PAMOD · SEQNO · PABEG/PAEND · PDBEZ/PDUNB · STDAZ | T550P |
| EmployeeAssignment | Pernr · ValidFrom/To · RuleId · EmploymentPct · TimeMgmtStatus · WeeklyHours | PERNR · BEGDA/ENDDA · SCHKZ · EMPCT · ZTERF · WOSTD | PA0007 |

**Datentypen** kommen direkt aus den DDIC-Elementen der Standardtabellen (CHAR/NUMC/DEC/DATS/TIMS) – im
Tool keine eigenen Domänen nötig.

---

## 6. Draft, Zeitabhängigkeit, Zugriffsschutz

- **Draft (nur Fiori):** RAP-Draft über technische Tabelle `ZAZP_D_*`; Aktivierung schreibt in die
  Standardtabellen (RAP `with unmanaged save`, → Service-Doku). SAP GUI (SM30) arbeitet ohne Draft direkt
  auf den Tabellen.
- **Zeitabhängigkeit:** `ValidFrom`/`ValidTo` (BEGDA/ENDDA) wie in den Standardtabellen; `@Semantics.
  businessDate.*` für zeitabhängige Auswahl.
- **Zugriffsschutz:** DCL-Rollen `ZI_ZAZP_*` (Access Control) zusätzlich zu den SAP-Standardberechtigungen
  (`S_TABU_*`, HR-Berechtigungen für IT0007).

---

## 7. Nächste Schritte

1. Restliche Interface-Views (`DailyWorkSchedule`, `BreakSchedule`, `EmployeeAssignment`, `RuleText`,
   Wertehilfen) nach dem Muster §3 anlegen; `key`-Felder an DDIC angleichen.
2. Projektions-Views `ZC_ZAZP_*` + Metadata-Extensions (`@UI`) für Fiori Elements.
3. Behavior/Logik → [`AZP-Service-Schicht.md`](AZP-Service-Schicht.md).
