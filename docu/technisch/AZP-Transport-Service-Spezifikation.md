# AZP-Tool – Transport (nativ) & CTS-Referenz

> Da die Logik **in SAP (ABAP/RAP)** liegt, wird das AZP-Customizing **nativ** über das Change- &
> Transport-System (CTS) auf einem Transportauftrag aufgezeichnet – **kein externer Transport-Service**.
> Dieses Dokument beschreibt den nativen Ablauf und dient als **Referenz der CTS-Bausteine** für die
> `ZCL_ZAZP_PERSIST`-Implementierung. Alle Bausteine/Tabellen sind gegen das Live-System (`ABAP-S4P`)
> verifiziert. Stand: 2026-07-17

---

## 1. Grundsatz

AZP-Definitionen (`T508A`, `T551A`, `T550A`, `T550P` + Texte) sind **Customizing** und werden beim
Speichern auf einem **Customizing-Auftrag** aufgezeichnet. Das passiert **im SAP-System selbst**:

- **SAP GUI (SM30/`SPRO`):** die Standard-**Auftragsabfrage** erscheint automatisch beim Sichern.
- **Fiori (RAP):** das Speichern (`ZCL_ZAZP_PERSIST`, unmanaged save) schreibt die Tabellen **und**
  zeichnet die Schlüssel über die CTS-Bausteine (§4) auf dem gewählten Auftrag auf.

**Nicht betroffen:** Weg B (Infotyp 0007) – Stammdaten, kein Transport.
**Nicht im Scope:** Freigabe/Weitertransport DEV→QAS→PRD (Transportverwaltung).

---

## 2. Transportauswahl in der Fiori-UI

Da SM30 die Auftragsabfrage nativ mitbringt, betrifft die Auswahl nur die Fiori-Variante. Vor dem
Aktivieren wird der Ziel-Customizing-Auftrag gewählt oder neu angelegt:

```
┌ Speichern / In SAP übernehmen ──────────────────────────┐
│ Transportauftrag                                        │
│  (•) Vorhandenen wählen  [ DEVK900123 – AZP Q3/2026 ▾ ] │
│  ( ) Neuen anlegen       Beschreibung [____________]    │
│                          [Abbrechen]   [Übernehmen]     │
└─────────────────────────────────────────────────────────┘
```

Ohne gültigen Auftrag ist das Aktivieren gesperrt.

---

## 3. Aufzeichnungsmodell (was transportiert wird)

Je AZP werden die betroffenen Customizing-Sätze als **Tabellenschlüssel** auf dem Auftrag aufgezeichnet –
Objekttyp `R3TR TABU <Tabelle>`, Schlüssel in `E071K`:

| Tabelle | Aufgezeichnet als | Schlüssel (aus Tabellen-Keyfeldern) |
|---|---|---|
| `T508A` (+ `T508S`) | `TABU T508A` | Mandant + `SCHKZ` + Gruppierungen |
| `T551A` | `TABU T551A` | Mandant + `ZMODN` + `WONUM` (+ `MOTPR`) |
| `T550A` (+ `T550S`) | `TABU T550A` | Mandant + `MOTPR` + `TPROG` (+ Variante) |
| `T550P` | `TABU T550P` | Mandant + `PAMOD` + `SEQNO` (+ `MOTPR`) |

Auftragsköpfe/-texte in `E070`/`E07T`, Schlüssel in `E071K`.

---

## 4. CTS-Bausteine (Referenz für `ZCL_ZAZP_PERSIST`) — verifiziert

| Schritt | Baustein / Tabelle | Zweck |
|---|---|---|
| Offene Aufträge lesen (Fiori-Auswahl) | `TRINT_SELECT_REQUESTS` bzw. `E070`/`E07T` | Filter `TRFUNCTION='W'`, `TRSTATUS='D'`, opt. `AS4USER` |
| Auftragsinfo | `TR_READ_GLOBAL_INFO_OF_REQUEST` | Status/Details |
| Neuen Auftrag anlegen | `TR_INSERT_REQUEST_WITH_TASKS` | `wi_trfunction='W'` (Customizing) |
| Schlüssel prüfen | `TR_OBJECTS_CHECK` | Objektliste (`TABU`, Tabelle, Keys) prüfen |
| Schlüssel aufzeichnen | `TR_OBJECTS_INSERT` | füllt `E071`/`E071K` |
| *(Alternativ)* | SM30-View-Pflege | zeichnet Transport automatisch auf |
| Freigabe *(nicht im Scope)* | `TR_RELEASE_REQUEST` | – |

> Bei reiner SM30-/`SPRO`-Pflege ist **kein** eigener Aufruf nötig – die Aufzeichnung erfolgt durch die
> Standard-View-Pflege. Die Bausteine werden nur in `ZCL_ZAZP_PERSIST` (Fiori-Speicherweg) direkt genutzt.

---

## 5. Vorbedingungen, Berechtigungen, Fehler

**Vorbedingungen**
- AZP validierungsfrei (kein `E`, siehe [`AZP-Service-Schicht.md`](AZP-Service-Schicht.md) §4).
- Auftrag offen, modifizierbar, Typ Customizing.
- Zielmandant für Customizing geöffnet (`SCC4`).

**Berechtigungen:** `S_TRANSPRT` (Aufträge), `S_TABU_DIS`/`S_TABU_NAM` (Tabellen).

**Fehlerbehandlung** (jeweils als Meldung, Speichern gesperrt)
| Situation | Reaktion |
|---|---|
| Auftrag freigegeben/gesperrt | anderen Auftrag wählen |
| Tabelle nicht transportierbar | Abbruch mit Hinweis |
| Berechtigung fehlt | Abbruch mit Benutzer/Objekt |
| Zielmandant nicht Customizing-offen | Abbruch |

---

## 6. Referenzierte SAP-Objekte (verifiziert, System `ABAP-S4P`)

| Objekt | Typ / Paket | Zweck |
|---|---|---|
| `TRINT_SELECT_REQUESTS` | FB / SCTS_REQ | Aufträge selektieren |
| `TR_INSERT_REQUEST_WITH_TASKS` | FB / SCTS_REQ | Auftrag ohne Dialog anlegen |
| `TR_OBJECTS_CHECK` | FB / SCTS_OBJ | Objekte/Schlüssel prüfen |
| `TR_OBJECTS_INSERT` | FB / SCTS_OBJ | Objekte/Schlüssel aufzeichnen |
| `TR_READ_GLOBAL_INFO_OF_REQUEST` | FB / SCTS_LOG | Auftragsinfo lesen |
| `TR_RELEASE_REQUEST` | FB / SCTS_REQ | Freigabe (nicht im Scope) |
| `E070` / `E07T` | Tabelle / SCTS_REQ | Auftragsköpfe / Kurztexte |
| `E071K` | Tabelle / SCTS_REQ | Schlüsseleinträge der Aufträge |
