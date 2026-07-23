# AZP ABAP Mirror — Paket `ZAZP_HR_TIME`

**Sync-Datum:** 2026-07-23 · **System:** S4P · **Quelle:** SAP ADT via MCP (`user-ARC-1 S4P` / SAPRead, `version=active`, `force_refresh`)

Lokale Spiegelung aller Kernobjekte des AZP-HR-Time-Pakets (Paket `ZAZP_HR_TIME`), typbasiert unter `sap/`.

---

## Verzeichnislayout

| Ordner | Inhalt | Dateiendung |
|---|---|---|
| `clas/` | ABAP-Klassen inkl. Behavior Pool | `.clas.abap`, `.clas.locals_imp.abap` |
| `intf/` | Interfaces | `.intf.abap` |
| `prog/` | Reports und Includes (PROG/I) | `.prog.abap` |
| `fugr/zazp_sm30/` | Funktionsgruppe ZAZP_SM30 | `.abap` |
| `ddls/` | CDS View Entities | `.ddls.asddls` |
| `ddlx/` | Metadata Extensions | `.ddlx.asddlxs` |
| `dcls/` | Access Controls | `.dcls` |
| `bdef/` | Behavior Definitions | `.bdef` |
| `srvd/` | Service Definitions | `.srvd.asddlxs` |
| `srvb/` | Service Bindings (Metadaten) | `.srvb.json` |
| `tabl/` | Draft-Tabellen | `.tabl.asddls` |
| `msag/` | Nachrichtenklasse | `.msag.json` |

---

## Objekt-Inventar

### Klassen (`clas/`)

| Objekt | Datei | Status |
|---|---|---|
| `ZCL_ZAZP_VALIDATION` | `zcl_zazp_validation.clas.abap` | aktiv |
| `ZCL_ZAZP_PERSIST` | `zcl_zazp_persist.clas.abap` | aktiv |
| `ZCL_ZAZP_TRANSPORT` | `zcl_zazp_transport.clas.abap` | aktiv |
| `ZCL_ZAZP_GENERATION` | `zcl_zazp_generation.clas.abap` | aktiv |
| `ZCL_ZAZP_ASSIGNMENT` | `zcl_zazp_assignment.clas.abap` | aktiv |
| `ZBP_I_ZAZP_WORKSCHEDULERULE` | `zbp_i_zazp_workschedulerule.clas.abap` | aktiv |
| `ZBP_I_ZAZP_WORKSCHEDULERULE` (locals) | `zbp_i_zazp_workschedulerule.clas.locals_imp.abap` | aktiv (`readEmployeeAssignment`, `assignEmployee`) |

### Interface (`intf/`)

| Objekt | Datei | Status |
|---|---|---|
| `ZIF_ZAZP_VALIDATION` | `zif_zazp_validation.intf.abap` | aktiv |

### Programme / Includes (`prog/`)

| Objekt | Typ | Datei | Status |
|---|---|---|---|
| `ZAZP01` | PROG | `zazp01.prog.abap` | aktiv |
| `ZAZP_E2E` | PROG | `zazp_e2e.prog.abap` | aktiv |
| `ZAZP_ODATA_SEARCH_TEST` | PROG | `zazp_odata_search_test.prog.abap` | aktiv (`$TMP`) |
| `ZAZP_SM30_EVENTS` | PROG/I | `zazp_sm30_events.prog.abap` | aktiv (via `type=INCL`) |
| `ZAZP_SM30_F01` | PROG/I | `zazp_sm30_f01.prog.abap` | aktiv = EVENTS-Body; **inaktiver Draft** in S4PK913042 |

### Funktionsgruppe (`fugr/zazp_sm30/`)

| Objekt | Datei | Status |
|---|---|---|
| `SAPLZAZP_SM30` (main) | `saplzazp_sm30.abap` | aktiv (FUGR nicht in diesem Sync-Lauf neu gelesen) |
| `LZAZP_SM30TOP` / `UXX` / `F01` | `lzazp_sm30*.abap` | siehe frühere Syncs / SE80 |

### CDS Views (`ddls/`)

| Interface | Consumption / Abstract | Hinweise |
|---|---|---|
| `ZI_ZAZP_WORKSCHEDULERULE` | `ZC_ZAZP_WORKSCHEDULERULE` | Root; Felder **Status**, **StatusCriticality** |
| `ZI_ZAZP_RULETEXT` | — | |
| `ZI_ZAZP_WEEKPATTERN` | `ZC_ZAZP_WEEKPATTERN` | |
| `ZI_ZAZP_DAILYWORKSCHEDULE` | `ZC_ZAZP_DAILYWORKSCHEDULE` | TIMS-Normalisierung `''`/`240000` |
| `ZI_ZAZP_DAILYWORKSCHEDULETEXT` | — | |
| `ZI_ZAZP_BREAKSCHEDULE` | `ZC_ZAZP_BREAKSCHEDULE` | TIMS-Normalisierung |
| `ZI_ZAZP_EMPLOYEEASSIGNMENT` | `ZC_ZAZP_EMPLOYEEASSIGNMENT` | IT0007 |
| `ZI_ZAZP_HOLIDAYCALENDAR` | — | VH (THOCI) |
| `ZA_ZAZP_COPYPARAMS` | Action-Parameter | copyAsTemplate |
| `ZA_ZAZP_SIMPARAMS` | Action-Parameter | `simulateMonth` (Jahr/Monat) |
| `ZA_ZAZP_MONTHPARAMS` | Action-Parameter | Assignment (Pernr, RuleId, …) |
| `ZA_ZAZP_TRANSPORTPARAMS` | Action-Parameter | `createTransportRequest` / `setPreferredTransport` |
| `ZI_ZAZP_SIMDAY` | Action-Ergebnis | Simulation / Transport / Assignment-Payload |

**Nicht im System (404):** `ZI_ZAZP_PSGROUPINGVH`, `ZI_ZAZP_RULEIDVH` — VH läuft über `distinctValues` auf `ZC_ZAZP_WorkScheduleRule`. Lokale Orphan-Dateien ggf. noch unter `ddls/` vorhanden, **nicht** aus S4P überschrieben.

### RAP / Services

| Typ | Objekt | Datei | Status |
|---|---|---|---|
| DCLS | `ZI_ZAZP_WORKSCHEDULERULE` | `dcls/zi_zazp_workschedulerule.dcls` | aktiv (PFCG `S_TABU_NAM`/`S_TABU_DIS`) |
| DCLS | `ZI_ZAZP_DAILYWORKSCHEDULE` | `dcls/zi_zazp_dailyworkschedule.dcls` | aktiv (PFCG) |
| DCLS | `ZI_ZAZP_BREAKSCHEDULE` | `dcls/zi_zazp_breakschedule.dcls` | aktiv (PFCG) |
| BDEF | `ZI_ZAZP_WORKSCHEDULERULE` | `bdef/zi_zazp_workschedulerule.bdef` | Draft + Actions inkl. **readEmployeeAssignment**, **assignEmployee** |
| BDEF | `ZC_ZAZP_WORKSCHEDULERULE` | `bdef/zc_zazp_workschedulerule.bdef` | Projection; use actions inkl. Assignment |
| DDLX | `ZC_ZAZP_*` (Rule/Week/Daily/Break) | `ddlx/` | aktiv; Rule-UI: Status + Criticality |
| SRVD | `ZUI_ZAZP_WORKSCHEDULERULE` | `srvd/zui_zazp_workschedulerule.srvd.asddlxs` | aktiv |
| SRVB | `ZUI_ZAZP_RULE_UI` | `srvb/zui_zazp_rule_ui.srvb.json` | **published** (primäre App) |
| SRVB | `ZUI_ZAZP_RULE_O4` | `srvb/zui_zazp_rule_o4.srvb.json` | published (Web API) |
| TABL | `ZAZP_D_RULE` | `tabl/zazp_d_rule.tabl.asddls` | aktiv inkl. `status` / `statuscriticality` |
| TABL | `ZAZP_D_WEEK` / `DAILY` / `BREAK` | `tabl/zazp_d_*.tabl.asddls` | aktiv |

### Behavior-Actions (ZI / ZC)

| Action | Art | Parameter | Ergebnis |
|---|---|---|---|
| `copyAsTemplate` | instance | `ZA_ZAZP_CopyParams` | `$self` |
| `simulateMonth` | instance | `ZA_ZAZP_SimParams` | `ZI_ZAZP_SimDay[]` |
| `listTransportRequests` | static | — | `ZI_ZAZP_SimDay[]` |
| `createTransportRequest` | static | `ZA_ZAZP_TransportParams` | `ZI_ZAZP_SimDay` |
| `setPreferredTransport` | static | `ZA_ZAZP_TransportParams` | — |
| `readEmployeeAssignment` | static | `ZA_ZAZP_MonthParams` | `ZI_ZAZP_SimDay` |
| `assignEmployee` | static | `ZA_ZAZP_MonthParams` | `ZI_ZAZP_SimDay` |

### Nachrichtenklasse (`msag/`)

| Objekt | Datei | Hinweis |
|---|---|---|
| `ZAZP` | `zazp.msag.json` | SAPRead: `messages: []` (SE91 leer); JSON enthält lokale Text-Vorlage |

---

## Status-Felder (Root)

In `ZI_ZAZP_WorkScheduleRule` / Draft `ZAZP_D_RULE` / UI-DDLX:

| Feld | Bedeutung |
|---|---|
| `Status` | `Abgelaufen` / `Geplant` / `In SAP` (CASE auf `ValidTo`/`ValidFrom` vs. Systemdatum) |
| `StatusCriticality` | `1` / `2` / `5` — UI Criticality + Icon |

---

## Inaktive Objekte / Hinweise (Stand Sync)

| Objekt | Typ | Transport / Hinweis |
|---|---|---|
| `ZAZP_SM30_F01` | PROG/I | Inactive draft in **S4PK913042**; Mirror = active (= EVENTS-Body) |
| `ZAZP_ODATA_SEARCH_TEST` | PROG | Paket `$TMP` |
| `ZAZP_ODATA_SMOKE` | PROG | `$TMP` — nicht gespiegelt |
| FUGR `ZAZP_SM30` | FUGR | ggf. inaktiv; SE80-Aktivierung siehe Doku |

---

## Lesefehler / Einschränkungen

| Objekt | Problem |
|---|---|
| `ZI_ZAZP_PSGROUPINGVH` | **404** — existiert nicht in S4P |
| `ZI_ZAZP_RULEIDVH` | **404** — existiert nicht in S4P |
| `ZAZP` (MSAG) | lesbar, aber System-Texte leer |
| `ZUI_ZAZP_RULE_*` (SRVB) | nur JSON-Metadaten, kein AFF-Quelltext |
| FUGR-Includes | dieser Lauf: nicht erneut gelesen |

---

## Sync erneuern

```text
SAPRead type=<TYP> name=<OBJ> version=active force_refresh=true
CLAS locals: include=implementations
INCL: ZAZP_SM30_EVENTS / ZAZP_SM30_F01 (nicht PROG)
Paket-Inventar: SAPRead type=DEVC name=ZAZP_HR_TIME
```
