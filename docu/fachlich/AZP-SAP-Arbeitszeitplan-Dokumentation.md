# AZP-Tool – SAP-Arbeitszeitplan: Lösungs- & Designdokumentation

> Zielbild für das AZP-Tool auf Basis des realen SAP-HCM-Modells: Datenmodell, App→SAP-Mapping,
> Integration. Grundlage: SAP Help Portal (S/4HANA) + Live-DDIC (System `ABAP-S4P`, Paket `PTIM`).
> Stand: 2026-07-17

---

## 1. Überblick

Die Lösung liegt **in SAP (ABAP/RAP)**; SAP GUI und eine optionale Fiori-UI teilen dieselbe Logik.
Arbeitszeitpläne werden modelliert, validiert und über zwei getrennte Wege gepflegt:

- **Weg A – AZP-Definition (Customizing):** direkt in SAP (ABAP/RAP) gepflegt; beim Speichern über die
  **native** Transportauszeichnung einem Auftrag zugeordnet (SM30-Standardabfrage bzw. RAP) und im
  Standardprozess DEV→QAS→PRD transportiert. Kein externer Export nötig.
- **Weg B – Mitarbeiterzuordnung (Stammdaten):** Zuordnung der Regel pro Mitarbeiter über Infotyp 0007
  (`HR_MAINTAIN_MASTERDATA` bzw. SuccessFactors EC).

```
┌──────────────────────── SAP S/4HANA · Paket ZAZP_HR_TIME ────────────────────────┐
│  SAP GUI (SM30 / ZAZP01) ┐                       ┌ Fiori (RAP/OData, optional)     │
│                          ├── ZCL_ZAZP_VALIDATION ┤  (dieselbe Logik)               │
│  Weg A  Customizing:  T508A · T551A · T550A · T550P    → nativer Transport         │
│  Weg B  Stammdaten:   PA0007 (Infotyp 0007)                                        │
└───────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Das SAP-Arbeitszeitplan-Modell

```
T550P  Pausenplan            ──┐ via PAMOD
T550A  Tagesarbeitszeitplan  ◀─┘ (Z780, Z770 …)   ──┐ via TPRG1..TPRG7
T551A  Periodenarbeitszeitplan ("Wochenmuster")  ◀─┘ ──┐ via ZMODN
T508A  Arbeitszeitplanregel ("AZP-ID", SCHKZ)    ◀─────┘ + Texte T508S ──┐ via SCHKZ
PA0007 Infotyp 0007          ◀───────────────────────────────────────────┘  Mitarbeiter ↔ Regel
        └─ Generierung RPTKAL00 → T552A (Monatsplan) → Auswertung PT60
```

**Schlüsselverkettung:**
`PA0007.SCHKZ` → `T508A.SCHKZ` → `T508A.ZMODN` → `T551A.ZMODN` → `T551A.TPRG1..7` → `T550A.TPROG` → `T550A.PAMOD` → `T550P.PAMOD`

Verbindende Gruppierungen: `MOTPR` (Tagesplan-Gruppierung) über T551A/T550A/T550P; `MOSID`/`ZEITY`
(PS-/ES-Gruppierung) und `MOFID` (Feiertagskalender) an `T508A`.

---

## 3. Datenmodell / Tabellenreferenz (Live-DDIC, nur fachlich relevante Felder)

### `T508A` – Arbeitszeitplanregel (Work Schedule Rule) · *Customizing* · Texte in `T508S`
| Feld | Typ | Bedeutung |
|---|---|---|
| SCHKZ | CHAR(8) | Arbeitszeitplanregel-Schlüssel (= AZP-ID) |
| MOFID | CHAR(2) | Feiertagskalender-ID |
| MOSID / ZEITY | NUMC(2) / CHAR(1) | PS- / ES-Gruppierung |
| ZMODN | CHAR(4) | Periodenarbeitszeitplan (→ T551A) |
| MOTPR | NUMC(2) | Tagesplan-Gruppierung |
| BEGDA / ENDDA | DATS(8) | Gültig ab / bis |
| TGSTD / WOSTD / M1STD / JRSTD | DEC | Sollstunden Tag / Woche / Monat / Jahr (Ø) |
| WKWDY | DEC(5) | Arbeitstage pro Woche |

### `T551A` – Periodenarbeitszeitplan · *Customizing* · **= „Wochenmuster"**
| Feld | Typ | Bedeutung |
|---|---|---|
| ZMODN | CHAR(4) | Periodenarbeitszeitplan-Schlüssel (← T508A) |
| WONUM | NUMC(3) | Wochennummer (mehrwöchige Rotation) |
| MOTPR | NUMC(2) | DWS-Gruppierung |
| TPRG1 … TPRG7 | CHAR(4) | Tagesarbeitszeitplan Montag … Sonntag |

> Freier Tag = eigener Tagesplan mit 0 Sollstunden (Frei-DWS, z.B. `FREI`) in `TPRGx`, kein Leerwert.

### `T550A` – Tagesarbeitszeitplan (Daily Work Schedule) · *Customizing* · Texte in `T550S`
| Feld | Typ | Bedeutung |
|---|---|---|
| TPROG | CHAR(4) | Tagesarbeitszeitplan-Schlüssel (z.B. Z780) |
| MOTPR | NUMC(2) | DWS-Gruppierung |
| BEGDA / ENDDA | DATS(8) | Gültig ab / bis |
| SOLLZ | DEC(5) | Sollarbeitszeit (Stunden) |
| SOBEG / SOEND | TIMS(6) | Arbeitsbeginn / -ende |
| NOBEG / NOEND | TIMS(6) | Normalarbeitszeit-Rahmen |
| BTBEG/BTEND · ETBEG/ETEND | TIMS(6) | Toleranz Beginn / Ende |
| K1BEG / K1END | TIMS(6) | Kernzeit |
| PAMOD | CHAR(4) | Pausenplan-Schlüssel (→ T550P) |

### `T550P` – Pausenplan (Break Schedule) · *Customizing*
| Feld | Typ | Bedeutung |
|---|---|---|
| PAMOD | CHAR(4) | Pausenplan-Schlüssel (← T550A) |
| SEQNO | NUMC(2) | Pausen-Nr. (mehrere je Plan) |
| PABEG / PAEND | TIMS(6) | Pausenbeginn / -ende (feste Pause) |
| PDBEZ / PDUNB | DEC(4) | Bezahlte / unbezahlte Dauer |
| STDAZ | DEC(5) | Dynamische Pause nach x Arbeitsstunden |

### `PA0007` – Infotyp 0007 „Planned Working Time" · *Stammdaten (pro Mitarbeiter)*
| Feld | Typ | Bedeutung |
|---|---|---|
| PERNR | NUMC(8) | Personalnummer |
| BEGDA / ENDDA | DATS(8) | Gültig ab / bis |
| SCHKZ | CHAR(8) | Arbeitszeitplanregel (→ T508A) |
| ZTERF | NUMC(1) | Zeitwirtschaftsstatus |
| EMPCT | DEC(5) | Beschäftigungsgrad % |
| WOSTD / MOSTD / ARBST / JRSTD | DEC | Arbeitszeit Woche / Monat / Tag / Jahr |

---

## 4. App-Datenmodell → SAP-Mapping

| App-/CDS-Entität | SAP-Objekt | Schlüssel |
|---|---|---|
| `WorkScheduleRule` (AZP-ID, Kalender, Gruppierung, Gültigkeit) | T508A (+ Text T508S) | `SCHKZ`, `MOFID`, `MOSID`/`ZEITY`, `BEGDA/ENDDA` |
| `WeekPattern` (Woche, Mo…So) | T551A | `ZMODN`, `WONUM`, `TPRG1..7` |
| `DailyWorkSchedule` (Sollzeit, Rahmen, Kernzeit) | T550A (+ Text T550S) | `TPROG`, `SOLLZ`, `SOBEG/SOEND`, `NOBEG/NOEND`, `K1*` |
| `BreakSchedule` (feste/dynamische Pause) | T550P | `PAMOD`, `SEQNO`, `PABEG/PAEND`, `PDBEZ/PDUNB`, `STDAZ` |
| `MonthlyInfo` (Aggregation) | T508A (Ø) / T552A (generiert) | `WOSTD`, `M1STD`, `JRSTD` |
| `EmployeeAssignment` | PA0007 (IT0007) | `PERNR`, `SCHKZ` |

---

## 5. Integration & Änderungswege

| Ebene | Objekte | Änderungsweg | Schnittstelle |
|---|---|---|---|
| Customizing (AZP-Definition) | T508A, T551A, T550A, T550P | `SPRO` / `SM30`·`SM34`, Transport | **Weg A** – in SAP (ABAP/RAP), nativer Transport |
| Stammdaten (Zuordnung) | Infotyp 0007 (`PA0007`) | `PA30`/`PA40`, API | **Weg B** – `HR_MAINTAIN_MASTERDATA` bzw. EC-OData |
| Generiert / Auswertung | T552A, Zeitkonten | Report `RPTKAL00`, `PT60` | Batch/nachgelagert |

Vorgelagert im Tool: Validierung & Simulation (Wochensumme, Konsistenz Tag↔Woche, Ø-Werte gegen T508A).
Konkrete OData-/SOAP-Servicenamen für Weg B release-/systemabhängig gegen den API-Katalog bestätigen.

---

## 6. Umsetzungsschritte

1. **CDS-Views** `ZI_ZAZP_*` / `ZC_ZAZP_*` über die Standardtabellen (§3/§4) – siehe
   [`AZP-CDS-Datenmodell.md`](../technisch/AZP-CDS-Datenmodell.md).
2. **Zentrale Logik** `ZCL_ZAZP_VALIDATION` (+ Generierung/Persistenz) – siehe
   [`AZP-Service-Schicht.md`](../technisch/AZP-Service-Schicht.md).
3. **RAP-Behavior** + Service (OData V4) und **SM30-Validierungs-Events** an den Pflegeviews.
4. **Fiori-Elements-UI** (optional): List Report / Object Page inkl. Wochenmuster-Fragment.
5. **Weg B (Stammdaten)**: IT0007 über `HR_MAINTAIN_MASTERDATA` bzw. EC-OData.
6. **Zielszenario festlegen**: nur Definition (A), nur Zuordnung (B) oder beides; On-Prem vs.
   SuccessFactors bestimmt die Schnittstellen.

---

## 7. Quellen

- SAP Help Portal – S/4HANA, Human Resources: *Prerequisites from Personnel Administration* (Infotyp 0007).
  <https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/c6c3ffd90792427a9fee1a19df5b0925/103fe153038a424de10000000a174cb4.html>
- SAP Help Portal – S/4HANA, HCM Local Version: *Technical Details – Tables/Views (Work Schedules)*.
  <https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/621c00a46ed247ffa5a2a311de7e3535/e0c2dc53b5ef424de10000000a174cb4.html>
- Live-S/4HANA-DDIC (System `ABAP-S4P`, Paket `PTIM`): `T508A`, `T551A`, `T550A`, `T550P`, `PA0007`,
  Texttabellen `T508S`/`T550S`, Baustein `HR_MAINTAIN_MASTERDATA`.
