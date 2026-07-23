# AZP – ABAP-Implementierungsstand

Stand: 2026-07-23 · System S4P · Paket `ZAZP_HR_TIME` · Transporte u. a. `S4PK913039` / `S4PK913041`  
Lokaler Spiegel: [`sap/README.md`](../../sap/README.md) · Offene Punkte: [AZP-Offene-ToDos.md](AZP-Offene-ToDos.md)

---

## 1. Aktiv (ADT Syntax OK)

| Objekt | Stand |
|---|---|
| `ZIF_ZAZP_VALIDATION` | Context-API `validate_rule_ctx`, Message-Konstanten |
| `ZCL_ZAZP_VALIDATION` | Payload-Prüfung; DB-Load nur in `validate_rule` |
| `ZCL_ZAZP_PERSIST` | `save_rule` / `delete_rule` + CTS |
| `ZCL_ZAZP_TRANSPORT` | list / create / ensure / preferred |
| `ZCL_ZAZP_GENERATION` | Monatssimulation inkl. Feiertage |
| `ZCL_ZAZP_ASSIGNMENT` | IT0007 `read_current` / `assign_rule` (INS/MOD) |
| `ZI_`/`ZC_ZAZP_WorkScheduleRule` | inkl. virtueller Felder `Status` / `StatusCriticality` |
| BDEF `ZI_`/`ZC_` | Draft, Deep Create, Validierungen, Actions (copy, simulate, Transport, **Zuordnung**) |
| `ZBP_I_ZAZP_WORKSCHEDULERULE` | Behavior Pool inkl. `readEmployeeAssignment` / `assignEmployee` |
| `ZAZP01` / `ZAZP_E2E` | GUI-Validierung/Simulation bzw. Smoke-Report |
| Service `ZUI_ZAZP_RULE_UI` / `_O4` | published (Republish nach Action-Änderungen ggf. manuell) |

**GUI-Testpfad:** `/nZAZP01` · **Fiori-Testpfad:** List Report → Mitarbeiter zuordnen / Validieren / Transport / Simulation.

---

## 2. Manuell nachziehen (SE80 / SE91 / SE54 / FLP)

### 2.1 Nachrichtenklasse `ZAZP` (SE91)

Texte anlegen (Vorlage auch in `sap/msag/zazp.msag.json`):

| Nr | Text |
|---|---|
| 000 | `&1&2&3&4` |
| 001 | Arbeitszeitplanregel (SCHKZ) ist leer |
| 002 | Arbeitszeitplanregel &1 nicht gefunden |
| 003 | Gueltig-ab muss kleiner/gleich Gueltig-bis sein |
| 004–007 | Wochenstunden / Periodenplan / Tagesplan / Wochensumme |
| 010–018 | Tagesplan-Prüfungen |
| 020–023 | Pausenplan-Prüfungen |
| 030–032 | Transport / Löschen |
| 040–042 | IT0007-Zuordnung |
| 050–056 | RAP Transport / Copy / Simulation / Persist |

### 2.2 Transaktion `ZAZP01` (SE93) — erledigt

- TCode `ZAZP01` → Report `ZAZP01`, Paket `ZAZP_HR_TIME`
- Kurztext: AZP Validierung und Simulation

### 2.3 SM30-Events (SE54)

Include `ZAZP_SM30_EVENTS` enthält die Forms (Quelle aktiviert speichern ggf. in ADT nachziehen):

| View | Event | Form-Routine |
|---|---|---|
| `V_T508A` | 01 Vor dem Sichern | `ZAZP_VALIDATE_T508A` |
| `V_T550A` | 01 | `ZAZP_VALIDATE_T550A` |
| `V_T550P` | 01 | `ZAZP_VALIDATE_T550P` |
| `V_T551A` | 01 | `ZAZP_VALIDATE_T551A` |

**FUGR `ZAZP_SM30`:** In SE80/ADT aktivieren und im Hauptprogramm einbinden:

```abap
INCLUDE zazp_sm30_events.
```

(ADT-Massenaktivierung der FUGR war über MCP blockiert/fehlgeschlagen – lokal in ADT aktivieren.)

### 2.4 Inaktive Objekte bereinigen

| Objekt | Aktion |
|---|---|
| `ZAZP_SM30` / `SAPLZAZP_SM30` | In ADT aktivieren |
| `ZAZP_SM30_EVENTS` | Mit FUGR aktivieren |
| `ZAZP_SM30_F01` | optional löschen (Platzhalter) |
| `ZUI_ZAZP_RULE_O4` | **Published** via `/IWFND/V4_ADMIN` — siehe [AZP-OData-V4-Service.md](AZP-OData-V4-Service.md) |

---

## 3. Architektur (nach Fix)

```
validate_rule (DB lesen) ──┐
                           ├──► validate_rule_ctx (Payload/Context)
SM30 / Persist / RAP ──────┘         ├── validate_daily
                                     └── validate_break
```

- **SM30 / ZAZP01 / Persist** nutzen dieselbe Context-API.
- **RAP-Saver** mappt Entität → `ty_rule_data` → `save_rule` / `delete_rule` + CTS.

---

## 4. Web-UI / RAP (Stand 2026-07-19)

| Thema | Status |
|---|---|
| Draft + Projection-BDEF + Actions | **erledigt** |
| Abstract Entities / Metadata Extensions | **erledigt** |
| Deep Create Weeks/Daily/Break | **erledigt** |
| Service Binding `ZUI_ZAZP_RULE_O4` / `RULE_UI` | **published** |
| DCL Root/Daily/Break | angelegt (noch offenes `grant select`) |
| PFCG-Rollen / FLP-Kachel | noch manuell |

Details: [AZP-OData-V4-Service.md](AZP-OData-V4-Service.md), [AZP-Offene-ToDos.md](AZP-Offene-ToDos.md).

---

## 5. Lokale Spiegelung

Stand **2026-07-19** — vollständige Spiegelung des Pakets `ZAZP_HR_TIME` unter `sap/` (siehe `sap/README.md` für Inventar).

```
sap/
  README.md              # Inventar + Sync-Datum
  clas/                  # ZCL_* / ZBP_* (.clas.abap, .locals_imp.abap)
  intf/                  # ZIF_ZAZP_VALIDATION
  prog/                  # ZAZP01, ZAZP_SM30_EVENTS, ZAZP_SM30_F01
  fugr/zazp_sm30/        # SAPLZAZP_SM30, LZAZP_SM30TOP/UXX/F01
  ddls/                  # ZI_* / ZC_* CDS Views
  dcls/                  # Access Control
  bdef/                  # Behavior Definition
  srvd/ srvb/            # Service Definition / Binding (JSON)
  tabl/                  # Draft-Tabellen ZAZP_D_*
  msag/                  # Nachrichtenklasse-Vorlage ZAZP
```

**Hinweis inaktive Entwürfe:** FUGR `ZAZP_SM30` / `SAPLZAZP_SM30` (Entwurf: `INCLUDE zazp_sm30_events.`). FUGR-Aktivierung nur in SE80 — siehe [AZP-P1-Manuelle-Schritte.md](AZP-P1-Manuelle-Schritte.md). SRVB `ZUI_ZAZP_RULE_O4` ist published — [AZP-OData-V4-Service.md](AZP-OData-V4-Service.md).
