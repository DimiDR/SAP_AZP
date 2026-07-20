# AZP ABAP Mirror — Paket `ZAZP_HR_TIME`

**Sync-Datum:** 2026-07-19 · **System:** S4P · **Quelle:** SAP ADT via MCP (SAPRead)

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
| `dcls/` | Access Controls | `.dcls` |
| `bdef/` | Behavior Definitions | `.bdef` |
| `srvd/` | Service Definitions | `.srvd.asddlxs` |
| `srvb/` | Service Bindings (Metadaten) | `.srvb.json` |
| `tabl/` | Draft-Tabellen | `.tabl.asddls` |
| `msag/` | Nachrichtenklasse (Vorlage) | `.msag.json` |

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
| `ZBP_I_ZAZP_WORKSCHEDULERULE` (locals) | `zbp_i_zazp_workschedulerule.clas.locals_imp.abap` | aktiv |

### Interface (`intf/`)

| Objekt | Datei | Status |
|---|---|---|
| `ZIF_ZAZP_VALIDATION` | `zif_zazp_validation.intf.abap` | aktiv |

### Programme / Includes (`prog/`)

| Objekt | Typ | Datei | Status |
|---|---|---|---|
| `ZAZP01` | PROG | `zazp01.prog.abap` | aktiv |
| `ZAZP_SM30_EVENTS` | PROG/I | `zazp_sm30_events.prog.abap` | aktiv |
| `ZAZP_SM30_F01` | PROG/I | `zazp_sm30_f01.prog.abap` | aktiv (Platzhalter) |

### Funktionsgruppe (`fugr/zazp_sm30/`)

| Objekt | Datei | Status |
|---|---|---|
| `SAPLZAZP_SM30` (main, aktiv) | `saplzazp_sm30.abap` | aktiv |
| `SAPLZAZP_SM30` (main, Entwurf) | `saplzazp_sm30.inactive.abap` | **inaktiv** — bindet `lzazp_sm30f01` ein |
| `LZAZP_SM30TOP` | `lzazp_sm30top.abap` | aktiv |
| `LZAZP_SM30UXX` | `lzazp_sm30uxx.abap` | aktiv (generiert, leer) |
| `LZAZP_SM30F01` | `lzazp_sm30f01.abap` | Entwurf — Inhalt aus `ZAZP_SM30_EVENTS` (ADT-Leseproblem) |

### CDS Views (`ddls/`)

| Interface | Consumption / Abstract |
|---|---|
| `ZI_ZAZP_WORKSCHEDULERULE` | `ZC_ZAZP_WORKSCHEDULERULE` (transactional root) |
| `ZI_ZAZP_RULETEXT` | — |
| `ZI_ZAZP_WEEKPATTERN` | `ZC_ZAZP_WEEKPATTERN` |
| `ZI_ZAZP_DAILYWORKSCHEDULE` | `ZC_ZAZP_DAILYWORKSCHEDULE` |
| `ZI_ZAZP_DAILYWORKSCHEDULETEXT` | — |
| `ZI_ZAZP_BREAKSCHEDULE` | `ZC_ZAZP_BREAKSCHEDULE` |
| `ZI_ZAZP_EMPLOYEEASSIGNMENT` | `ZC_ZAZP_EMPLOYEEASSIGNMENT` |
| `ZI_ZAZP_HOLIDAYCALENDAR` | — |
| `ZA_ZAZP_COPYPARAMS` | Action-Parameter |
| `ZA_ZAZP_MONTHPARAMS` | Action-Parameter |
| `ZI_ZAZP_SIMDAY` | Action-Ergebnis |

### RAP / Services

| Typ | Objekt | Datei | Status |
|---|---|---|---|
| DCLS | `ZI_ZAZP_WORKSCHEDULERULE` | `dcls/zi_zazp_workschedulerule.dcls` | aktiv (offen grant) |
| DCLS | `ZI_ZAZP_DAILYWORKSCHEDULE` | `dcls/zi_zazp_dailyworkschedule.dcls` | aktiv (offen grant) |
| DCLS | `ZI_ZAZP_BREAKSCHEDULE` | `dcls/zi_zazp_breakschedule.dcls` | aktiv (offen grant) |
| BDEF | `ZI_ZAZP_WORKSCHEDULERULE` | `bdef/zi_zazp_workschedulerule.bdef` | aktiv (Draft + Deep Create + Actions) |
| BDEF | `ZC_ZAZP_WORKSCHEDULERULE` | `bdef/zc_zazp_workschedulerule.bdef` | aktiv (Projection + children) |
| DDLX | `ZC_ZAZP_*` (Rule/Week/Daily/Break) | `ddlx/` | aktiv |
| SRVD | `ZUI_ZAZP_WORKSCHEDULERULE` | `srvd/zui_zazp_workschedulerule.srvd.asddlxs` | aktiv |
| SRVB | `ZUI_ZAZP_RULE_O4` | `srvb/zui_zazp_rule_o4.srvb.json` | published (Web API) |
| SRVB | `ZUI_ZAZP_RULE_UI` | `srvb/zui_zazp_rule_ui.srvb.json` | **published** (primäre App) |
| TABL | `ZAZP_D_RULE` | `tabl/zazp_d_rule.tabl.asddls` | aktiv |
| TABL | `ZAZP_D_WEEK` / `DAILY` / `BREAK` | `tabl/zazp_d_*.tabl.asddls` | aktiv (Composition-Draft) |

### Nachrichtenklasse (`msag/`)

| Objekt | Datei | Hinweis |
|---|---|---|
| `ZAZP` | `zazp.msag.json` | Vorlage — Texte im System (SE91) noch leer |

---

## Inaktive Objekte im System (Stand Sync)

| Objekt | Typ | Transport |
|---|---|---|
| `ZAZP_SM30` | FUGR | — |
| `SAPLZAZP_SM30` | FUGR/I | S4PK913042 |
| `ZUI_ZAZP_RULE_O4` | SRVB | S4PK913042 |

**FUGR-Entwurf:** Inaktive Version von `SAPLZAZP_SM30` enthält `INCLUDE zazp_sm30_events.` (Syntax OK). ADT-Aktivierung der FUGR schlägt fehl → in **SE80** aktivieren (siehe `docu/technisch/AZP-P1-Manuelle-Schritte.md`).

---

## Lesefehler / Einschränkungen

| Objekt | Problem |
|---|---|
| `ZAZP_SM30_EVENTS`, `ZAZP_SM30_F01` | Typ PROG/I (Include), nicht PROG — gelesen via `SAPRead type=INCL` |
| `LZAZP_SM30F01` | ADT: `[Could not read include]` — gespiegelt aus `ZAZP_SM30_EVENTS` |
| `ZUI_ZAZP_RULE_O4` | Nur Metadaten (JSON), kein AFF-Quelltext |
| `ZAZP` (MSAG) | System leer — Vorlage aus `zazp.msag.json` |

---

## Sync erneuern

```text
SAPRead type=<TYP> name=<OBJ> version=active
FUGR: expand_includes=true, version=auto
CLAS locals: include=implementations
INCL: ZAZP_SM30_EVENTS / ZAZP_SM30_F01 (nicht PROG)
```
