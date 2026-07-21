# AZP – Offene ToDos

Stand: 2026-07-20 · Paket `ZAZP_HR_TIME` · System S4P  
Bezug: [AZP-ABAP-Implementierungsstand.md](AZP-ABAP-Implementierungsstand.md) · GUI-Rest: [AZP-P1-Manuelle-Schritte.md](AZP-P1-Manuelle-Schritte.md)

Legende: **P1** blockiert GUI-Produktivnutzung · **P2** sinnvoll vor Abnahme · **P3** Web-UI / später

---

## P1 – Sofort (SAP GUI fertigmachen)

| # | ToDo | Status | Hinweis |
|---|---|---|---|
| 1 | Nachrichtenklasse `ZAZP` befüllen | **GUI** | Vorlage: `sap/msag/zazp.msag.json` (+ XML `zazp.messageclass.xml`). Klasse existiert, Texte in T100 noch leer. ADT-MSAG-Write nicht verfügbar. |
| 2 | ~~Transaktion `ZAZP01` anlegen~~ | Erledigt | TCode `ZAZP01` → Report `ZAZP01` |
| 3 | ~~Include `ZAZP_SM30_EVENTS` aktivieren~~ | Erledigt | Forms aktiv als PROG-Include |
| 4 | FUGR `ZAZP_SM30` aktivieren | **GUI (SE80)** | Inaktiver Entwurf hat `INCLUDE zazp_sm30_events.` — ADT-Aktivierung schlägt fehl (bekannt). In SE80 Strg+F3. |
| 5 | Platzhalter `ZAZP_SM30_F01` leeren/löschen | **GUI** | Nach FUGR-Aktivierung; Duplikat, nicht im Hauptprogramm |
| 6–9 | SM30-Event 01 an `V_T508A/T550A/T550P/T551A` | **GUI (SE54)** | Form + Prog `SAPLZAZP_SM30` — erst nach #4 |

> Klickpfade: **[AZP-P1-Manuelle-Schritte.md](AZP-P1-Manuelle-Schritte.md)** (~10 Min)

---

## P2 – Vor fachlicher Abnahme

| # | ToDo | Status | Hinweis |
|---|---|---|---|
| 10 | E2E Validierung | **Report bereit** | `/nSE38` → `ZAZP_E2E` (Default `NORM` / `08` / `01`) |
| 11 | E2E Monatssimulation + Feiertag | **Report bereit** | gleicher Report; prüft `is_holiday` / `day_type = 2` |
| 12 | Persist + Transport | **teilweise** | Report prüft offene Customizing-Aufträge + `ensure_*`. Keys in `E071K` nach Fiori-/SM30-Save prüfen. Offene W-Aufträge existieren im System. |
| 13 | IT0007-Zuordnung | **teilweise** | Report: Read-only mit `P_PERNR` (kein Write). Write braucht `P_ORGIN` + echte Personalnummer. |
| 14 | ~~DCL `aspect pfcg_auth`~~ | **Erledigt** | Root/Daily/Break: `S_TABU_NAM` + `S_TABU_DIS` (`DICBERCLS = 'PC'`) |
| 15 | ~~DCL Daily/Break anlegen~~ | Erledigt | |
| 16 | ATC Literale → MSAG | **teilweise** | `add_message` löst jetzt `MESSAGE ID 'ZAZP' … INTO` auf; Call-Site-Literale bleiben bis SE91 (#1) als Fallback. SELECT-SINGLE-Findings optional. |
| 17 | ~~Textsymbole Report `ZAZP01`~~ | Erledigt | |

---

## P3 – Web-UI

| # | ToDo | Status | Hinweis |
|---|---|---|---|
| 18–23b, 26 | Draft / Actions / Binding / Composition | Erledigt | |
| 24 | Launchpad-Kachel | **GUI / FLP** | Inbound in `manifest.json` vorhanden (`azpworkschedulerule` / `tile`). MCP-FLP-Write blockiert (`allowWrites=false`). Catalog/Group/Tile manuell. |
| 25 | PFCG-Rollen `ZAZP_VIEWER/EDITOR/ADMIN` | **GUI (PFCG)** | Konzept: [AZP-Rollen-Berechtigungskonzept.md](../fachlich/AZP-Rollen-Berechtigungskonzept.md). Auth-Gruppe Tabellen = `PC`. |

---

## Bereits erledigt (2026-07-20 Nachzug)

- DCL Root/Daily/Break auf `pfcg_auth` umgestellt und aktiviert  
- `ZCL_ZAZP_VALIDATION=>add_message` → MSAG-Auflösung via `MESSAGE … INTO`  
- Report `ZAZP_E2E` (P2 #10–#13 Smoke) angelegt + aktiv  
- Lokale MSAG-Vorlage um RAP-Meldungen `050`–`056` ergänzt  

---

## Aktuell inaktiv im System (Aufräumen)

| Objekt | Typ | Aktion |
|---|---|---|
| `ZAZP_SM30` / `SAPLZAZP_SM30` | FUGR | **SE80 aktivieren** (Entwurf: `INCLUDE zazp_sm30_events.`) |
| `ZAZP_SM30_F01` | INCL | nach Aktivierung leeren/löschen |
| `ZTEST_MCP_TMP` | TABL | Testobjekt — ggf. löschen |

---

## Empfohlene Reihenfolge (Rest-GUI)

1. **SE91** `ZAZP` Texte aus `sap/msag/zazp.msag.json` (mind. `000`)  
2. **SE80** FUGR `ZAZP_SM30` aktivieren  
3. **SE54** Events 01 an die vier Views  
4. `/nSE38` → `ZAZP_E2E` laufen lassen  
5. PFCG-Rollen + FLP-Kachel  
