# AZP P1 – Manuelle Schritte in S4P (SE80 / SE91 / SE93 / SE54)

Stand: 2026-07-19 · Paket `ZAZP_HR_TIME` · Transportaufgabe `S4PK913042` (Auftrag `S4PK913041`)

Per MCP bereits erledigt: Include `ZAZP_SM30_EVENTS` aktiv; FUGR-Hauptprogramm enthält im **inaktiven Entwurf**  
`INCLUDE zazp_sm30_events.` (Syntax OK). ADT-Aktivierung der FUGR schlägt systemseitig fehl → **in SE80 aktivieren**.

---

## 1. Nachrichtenklasse `ZAZP` (SE91) — ca. 2 Min

1. Transaktion **SE91** → Nachrichtenklasse `ZAZP` → Ändern  
2. Texte aus `sap/msag/zazp.msag.json` übernehmen (mind. `000` = `&1&2&3&4`)  
3. Speichern / Aktivieren auf Transport `S4PK913042`

| Nr | Text |
|---|---|
| 000 | `&1&2&3&4` |
| 001 | Arbeitszeitplanregel (SCHKZ) ist leer |
| 002 | Arbeitszeitplanregel &1 nicht gefunden |
| 003 | Gueltig-ab muss kleiner/gleich Gueltig-bis sein |
| 004 | Durchschnittswochenstunden ausserhalb Bereich |
| 005 | Periodenarbeitszeitplan &1 nicht gefunden |
| 006 | Tagesplan &1 existiert nicht |
| 007 | Wochensumme weicht von Ø-Wochenwert ab |
| 010–018 | Tagesplan-Prüfungen (siehe JSON) |
| 020–023 | Pausenplan-Prüfungen |
| 030–032 | Transport / Löschen |
| 040–042 | IT0007-Zuordnung |

---

## 2. Transaktion `ZAZP01` (SE93) — **erledigt**

| | |
|---|---|
| TCode | `ZAZP01` |
| Kurztext | AZP Validierung und Simulation |
| Startobjekt | Report `ZAZP01` |
| Paket | `ZAZP_HR_TIME` |

Aufruf: `/nZAZP01`

---

## 3. FUGR `ZAZP_SM30` aktivieren (SE80) — ca. 2 Min

1. **SE80** → Funktionsgruppe `ZAZP_SM30`  
2. Hauptprogramm `SAPLZAZP_SM30` öffnen — Entwurf sollte enthalten:

```abap
  INCLUDE zazp_sm30_events.                  " SM30 Event Form-Routinen
```

3. Gesamte Funktionsgruppe **aktivieren** (Strg+F3)  
4. Optional: Include `ZAZP_SM30_F01` leeren oder löschen (Duplikat der Forms; nicht im Hauptprogramm eingebunden)

Falls Aktivierung mit Fehler zur Include-Zuordnung: Forms alternativ in neues FUGR-Include `LZAZP_SM30F01` legen (SE80 → Rechtsklick Includes → Create) und `INCLUDE lzazp_sm30f01.` verwenden. Vorlage: `sap/prog/zazp_sm30_events.prog.abap`.

---

## 4. SM30-Events (SE54) — ca. 5 Min

Für jede Pflege-View: **SE54** → View → Environment → Modification → Events → New entries:

| View | Event | Form | Programm |
|---|---|---|---|
| `V_T508A` | 01 (Vor dem Sichern) | `ZAZP_VALIDATE_T508A` | `SAPLZAZP_SM30` |
| `V_T550A` | 01 | `ZAZP_VALIDATE_T550A` | `SAPLZAZP_SM30` |
| `V_T550P` | 01 | `ZAZP_VALIDATE_T550P` | `SAPLZAZP_SM30` |
| `V_T551A` | 01 | `ZAZP_VALIDATE_T551A` | `SAPLZAZP_SM30` |

Customizing-Auftrag wählen (offen, Typ W).

---

## 5. Kurztest

1. `/nZAZP01` → gültige `SCHKZ` → Validierung + Simulation  
2. SM30 `V_T508A` → Speichern mit absichtlich ungültigen Daten → gleiche Fehler wie Report  

**Fertig**, wenn beide Wege dieselben Meldungen liefern.
