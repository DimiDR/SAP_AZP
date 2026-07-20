# AZP-Tool – Arbeitszeitplan-Verwaltung für SAP HCM

Werkzeug zum komfortablen **Modellieren, Validieren und Pflegen von Arbeitszeitplänen (AZP)** in
SAP HCM (S/4HANA / ECC, Modul PT – Personalzeitwirtschaft). Die **Logik liegt in SAP (ABAP)** – dadurch
funktioniert **SAP GUI voll und ohne Fiori**, und eine optionale **Fiori-Oberfläche (RAP → OData)** nutzt
**denselben** Code.

> **Namenskonvention:** Paket **`ZAZP_HR_TIME`** (Kunden-Z-Namensraum). Objekte: `ZAZP_*` (DDIC/Tabellen),
> `ZCL_ZAZP_*` (Klassen), `ZI_ZAZP_*` / `ZC_ZAZP_*` (CDS), Transaktion `ZAZP01`.

---

## Architektur auf einen Blick

Ausführliche Diagramme (Schichten, Klassen-Aufrufe, RAP, Tabellen):
**[AZP-Architektur.md](technisch/AZP-Architektur.md)**.

```
┌──────────────────────── SAP S/4HANA · Paket ZAZP_HR_TIME ─────────────────────────┐
│                                                                                    │
│   Zentrale Logik:   ZCL_ZAZP_VALIDATION  (Plausibilität, Payload + DB)             │
│                     ZCL_ZAZP_PERSIST / TRANSPORT / GENERATION / ASSIGNMENT          │
│                     + Standard RPTKAL00 (Monatsgenerierung), Zeitauswertung        │
│                          ▲                                ▲                         │
│            ┌─────────────┘                                └─────────────┐          │
│     SAP GUI (klassisch)                                        RAP-Business-Objekt │
│      SM30-Events / Report+TCode ZAZP01                       ZI_ZAZP_* + Behavior  │
│      → volle Prüfung, ohne Fiori                             (Validations + Save)  │
│                                                                    │ OData v4      │
│   Daten (Customizing):  T508A · T551A · T550A · T550P              ▼               │
│   Stammdaten:           PA0007 (IT0007)                   Fiori Elements App       │
│   Transport:            nativ (CTS)                                                │
└────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Dokumentation

Die Dokumentation ist in **fachlich** und **technisch** unterteilt.

### [Fachliche Dokumentation](fachlich/)

| Dokument | Inhalt |
|---|---|
| [AZP-SAP-Arbeitszeitplan-Dokumentation.md](fachlich/AZP-SAP-Arbeitszeitplan-Dokumentation.md) | SAP-Datenmodell, Objektkette, Integrationswege A/B |
| [AZP-Frontend-Dokumentation.md](fachlich/AZP-Frontend-Dokumentation.md) | Oberflächen-Zielbild (GUI jetzt, Fiori später) |
| [AZP-Rollen-Berechtigungskonzept.md](fachlich/AZP-Rollen-Berechtigungskonzept.md) | Rollenmodell, Aktivitätsmatrix, PFCG / DCL |

### [Technische Dokumentation](technisch/)

| Dokument | Inhalt |
|---|---|
| [AZP-Architektur.md](technisch/AZP-Architektur.md) | Schichten, Klassen-Aufrufe, RAP-Composition, Tabellenzugriffe |
| [AZP-CDS-Datenmodell.md](technisch/AZP-CDS-Datenmodell.md) | CDS über Standardtabellen |
| [AZP-Service-Schicht.md](technisch/AZP-Service-Schicht.md) | Logik-Klassen, RAP-Behavior, SM30-Events |
| [AZP-Transport-Service-Spezifikation.md](technisch/AZP-Transport-Service-Spezifikation.md) | Nativer CTS-Transport |
| [AZP-ABAP-Objektliste.md](technisch/AZP-ABAP-Objektliste.md) | Umsetzungs-Checkliste aller ABAP-Objekte |
| [AZP-ABAP-Implementierungsstand.md](technisch/AZP-ABAP-Implementierungsstand.md) | Aktueller ABAP-Stand (ohne Web-UI) |
| [AZP-Offene-ToDos.md](technisch/AZP-Offene-ToDos.md) | Offene ToDos (P1 GUI / P2 Abnahme / P3 Web-UI) |
| [AZP-P1-Manuelle-Schritte.md](technisch/AZP-P1-Manuelle-Schritte.md) | P1-Klickpfade SE91/SE93/SE80/SE54 (~10 Min) |
| [AZP-OData-V4-Service.md](technisch/AZP-OData-V4-Service.md) | OData V4 Binding publish, korrekte URL, Smoke-Test |

---

## SAP-Objektkette (Kernmodell)

```
PA0007.SCHKZ → T508A.SCHKZ → T508A.ZMODN → T551A.ZMODN → T551A.TPRG1..7
             → T550A.TPROG → T550A.PAMOD → T550P.PAMOD
```

`T508A`-Schlüssel (CDS/RAP): `ZEITY + MOFID + MOSID + SCHKZ + ENDDA`.

---

## Status

**ABAP-Kern + Web-UI (Deep Create) umgesetzt** in S4P, Paket `ZAZP_HR_TIME`.  
**Lokale Spiegelung** unter `sap/` (typbasiert, Sync 2026-07-19) — siehe [sap/README.md](../sap/README.md).

- Validierung (`validate_rule_ctx`), Persist/Delete, Feiertage, RAP-Behavior inkl. Draft/Actions/Deep Create.
- GUI: Transaktion `/nZAZP01` + Include `ZAZP_SM30_EVENTS` aktiv; Rest P1 (SE91/SE80-FUGR/SE54) → [P1-Manuelle-Schritte](technisch/AZP-P1-Manuelle-Schritte.md).
- Web-UI: Fiori Elements App `app/azp-workschedulerule/` gegen Live-Service `ZUI_ZAZP_RULE_UI` (auch `RULE_O4` published). Object Page: Regel + Wochenmuster + Tagespläne + Pausen. Offen: PFCG / FLP-Kachel / DCL-Auth → [Offene ToDos](technisch/AZP-Offene-ToDos.md).

Stand: 2026-07-19.
