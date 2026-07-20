# AZP – Offene ToDos

Stand: 2026-07-19 · Paket `ZAZP_HR_TIME` · System S4P  
Bezug: [AZP-ABAP-Implementierungsstand.md](AZP-ABAP-Implementierungsstand.md)

Legende: **P1** blockiert GUI-Produktivnutzung · **P2** sinnvoll vor Abnahme · **P3** Web-UI / später

---

## P1 – Sofort (SAP GUI fertigmachen)

| # | ToDo | Wo | Hinweis |
|---|---|---|---|
| 1 | Nachrichtenklasse `ZAZP` befüllen | SE91 | Vorlage: `sap/msag/zazp.msag.json` — Schritte: [AZP-P1-Manuelle-Schritte.md](AZP-P1-Manuelle-Schritte.md) |
| 2 | ~~Transaktion `ZAZP01` anlegen~~ | SE93 | **Erledigt** — TCode `ZAZP01` → Report `ZAZP01`, Paket `ZAZP_HR_TIME` |
| 3 | ~~Include `ZAZP_SM30_EVENTS` aktivieren~~ | ADT | **Erledigt** |
| 4 | FUGR `ZAZP_SM30` aktivieren | **SE80** | Entwurf hat `INCLUDE zazp_sm30_events.` (Syntax OK); ADT-Aktivierung schlägt fehl |
| 5 | Platzhalter `ZAZP_SM30_F01` löschen oder leeren | SE80 | Duplikat; nicht im Hauptprogramm eingebunden |
| 6 | SM30-Event 01 an `V_T508A` | SE54 | Form `ZAZP_VALIDATE_T508A` / Prog `SAPLZAZP_SM30` |
| 7 | SM30-Event 01 an `V_T550A` | SE54 | Form `ZAZP_VALIDATE_T550A` |
| 8 | SM30-Event 01 an `V_T550P` | SE54 | Form `ZAZP_VALIDATE_T550P` |
| 9 | SM30-Event 01 an `V_T551A` | SE54 | Form `ZAZP_VALIDATE_T551A` |

> Klickpfade gebündelt: **[AZP-P1-Manuelle-Schritte.md](AZP-P1-Manuelle-Schritte.md)** (~10 Min)

**Abnahmekriterium P1:** Speichern in SM30 liefert dieselben Fehler wie `ZAZP01`; Transaktion startet den Report.

---

## P2 – Vor fachlicher Abnahme

| # | ToDo | Hinweis |
|---|---|---|
| 10 | End-to-End-Test Validierung an echter `T508A`-Regel | Report `ZAZP01` mit gültiger SCHKZ |
| 11 | End-to-End-Test Monatssimulation inkl. Feiertag | `is_holiday` / DayType `2` prüfen |
| 12 | Persist + Transport testen | Customizing-Auftrag offen; Keys in `E071K` prüfen |
| 13 | IT0007-Zuordnung testen | `ZCL_ZAZP_ASSIGNMENT` (Berechtigung `P_ORGIN` nötig) |
| 14 | DCL absichern (`aspect pfcg_auth`) | Root/Daily/Break DCL **angelegt** (offen `grant select`); Auth mit PFCG nachziehen |
| 15 | ~~DCL für Daily/Break nachziehen~~ | **Erledigt** — `ZI_ZAZP_DailyWorkSchedule` / `BreakSchedule` DCL aktiv |
| 16 | ATC-Findings bereinigen (optional) | Literale → Message-Klasse; `SELECT SINGLE` Unique Keys |
| 17 | ~~Textsymbole Report `ZAZP01`~~ | **Erledigt** — Selektionstexte + Blocktitel in `INITIALIZATION` (kein ADT-Textpool) |

---

## P3 – Web-UI

| # | ToDo | Hinweis |
|---|---|---|
| 18 | ~~Draft in BDEF aktivieren (`zazp_d_rule`)~~ | **Erledigt** — Keys an T508A-PK angeglichen |
| 19 | ~~Abstract Entities `ZA_ZAZP_CopyParams`, `ZA_ZAZP_MonthParams`, `ZI_ZAZP_SimDay`~~ | **Erledigt** |
| 20 | ~~RAP-Actions `copyAsTemplate`, `simulateMonth`~~ | **Erledigt** |
| 21 | ~~Projection-BDEF `ZC_ZAZP_WorkScheduleRule`~~ | **Erledigt** — transactional_query + draft |
| 22 | ~~Metadata Extensions (List Report / Object Page)~~ | **Erledigt** — `ZC_ZAZP_WorkScheduleRule` DDLX |
| 23 | ~~Service Binding `ZUI_ZAZP_RULE_O4` publish~~ | **Erledigt** via `/IWFND/V4_ADMIN` |
| 23b | ~~Binding `ZUI_ZAZP_RULE_UI` (V4 UI) publish~~ | **Erledigt** via `/IWFND/V4_ADMIN` |
| 24 | Launchpad-Kachel | App fertig (`app/azp-workschedulerule/` + Inbound); FLP Catalog/Group manuell |
| 25 | PFCG-Rollen `ZAZP_VIEWER` / `EDITOR` / `ADMIN` | manuell in PFCG |
| 26 | ~~Wochenmuster/Tagespläne/Pausen als Composition~~ | **Erledigt** — Deep Create inkl. Draft |

---

## Bereits erledigt (kein ToDo)

- Logik-Klassen: Validation / Persist / Transport / Generation / Assignment  
- CDS-Schlüssel korrigiert (`T508A`-PK)  
- RAP Behavior Pool (Validierungen + Saver + Draft + Actions)  
- Report + Transaktion `ZAZP01` (`/nZAZP01`)  

- Include `ZAZP_SM30_EVENTS` aktiv (Quelle in `sap/prog/`)  
- Lokale Spiegelung `sap/` strukturiert (Sync 2026-07-19, siehe `sap/README.md`)  
- Dokumentation Kernstand  
- Service Binding `ZUI_ZAZP_RULE_O4` aktiviert + Gateway-Publish (`/IWFND/V4_ADMIN`) — [AZP-OData-V4-Service.md](AZP-OData-V4-Service.md)
- Draft / Projection-BDEF / Actions / Metadata Extension (P3 Kern)
- Deep Create Composition Weeks/Daily/Break + Draft-Tabellen + Saver
- DCL Root/Daily/Break (strukturell; Auth noch offen)

---

## Aktuell inaktiv im System (Aufräumen)

| Objekt | Typ | Aktion |
|---|---|---|
| `ZAZP_SM30` / `SAPLZAZP_SM30` | FUGR | SE80 aktivieren — Entwurf: `INCLUDE zazp_sm30_events.` |
| `ZAZP_SM30_F01` | INCL | leeren/löschen (Duplikat) |
| `ZTEST_MCP_TMP` | TABL | Testobjekt — ggf. löschen |
| `ZAZP_ODATA_SMOKE` | PROG ($TMP) | optional löschen (Smoke-Test Publish/URL) |

---

## Empfohlene Reihenfolge

1. Fiori-App gegen Live-Service starten (`npm start`) → Anlegen / Kopieren / Simulieren  
2. SE91 Texte → ~~SE93 TCode~~ → FUGR+Include → SE54 Events (P1)  
3. Tests P2 → PFCG/FLP
