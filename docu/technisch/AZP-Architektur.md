# AZP – Architekturübersicht

Wie die Schichten aufgebaut sind, welche Einstiege welche Klassen rufen und
welche SAP-Tabellen betroffen sind. Paket: **`ZAZP_HR_TIME`**.

> Ergänzend: [Service-Schicht](AZP-Service-Schicht.md) · [CDS-Modell](AZP-CDS-Datenmodell.md) · [Transport](AZP-Transport-Service-Spezifikation.md)

Stand: 2026-07-20

---

## 1. Schichtenmodell

Drei Einstiege, **eine** Logikschicht, **keine** eigenen Z-Datentabellen
(außer Draft-Hilfstabellen für RAP).

```mermaid
flowchart TB
  subgraph UI["Einstieg"]
    GUI["SAP GUI<br/>TCode ZAZP01"]
    SM30["SM30<br/>V_T508A / V_T551A / V_T550A / V_T550P"]
    FIORI["Fiori Elements<br/>OData V4 · ZUI_ZAZP_RULE_UI"]
  end

  subgraph RAP["RAP / OData"]
    SRVD["Service Definition<br/>ZUI_ZAZP_WORKSCHEDULERULE"]
    BDEF["Behavior<br/>ZI_ZAZP_WorkScheduleRule"]
    ZBP["Behavior Pool<br/>ZBP_I_ZAZP_WORKSCHEDULERULE"]
  end

  subgraph LOGIC["ABAP-Logik · ZCL_ZAZP_*"]
    VAL["VALIDATION"]
    PER["PERSIST"]
    TRN["TRANSPORT"]
    GEN["GENERATION"]
    ASN["ASSIGNMENT"]
  end

  subgraph DATA["SAP-Standarddaten"]
    CUST["Customizing<br/>T508A · T508S · T551A<br/>T550A · T550S · T550P"]
    PA["Stammdaten<br/>PA0007"]
    CTS["CTS<br/>E070 / E07T"]
  end

  GUI --> VAL
  GUI --> GEN
  SM30 --> VAL
  FIORI --> SRVD --> BDEF --> ZBP
  ZBP --> VAL
  ZBP --> PER
  ZBP --> TRN
  ZBP --> GEN
  PER --> VAL
  PER --> TRN
  PER --> CUST
  VAL --> CUST
  GEN --> CUST
  TRN --> CTS
  ASN -.-> PA
```

`ASSIGNMENT` ist über RAP-Actions `readEmployeeAssignment` / `assignEmployee` und den Fiori-Dialog angebunden (durchgezogene Linie).

---

## 2. Klassen – wer ruft wen?

```mermaid
flowchart LR
  subgraph Entry["Einstiege / RAP"]
    Z01["ZAZP01"]
    SM["SM30 Forms"]
    ZBP2["ZBP_I_ZAZP_WORKSCHEDULERULE"]
  end

  VAL2["ZCL_ZAZP_VALIDATION"]
  PER2["ZCL_ZAZP_PERSIST"]
  TRN2["ZCL_ZAZP_TRANSPORT"]
  GEN2["ZCL_ZAZP_GENERATION"]
  ASN2["ZCL_ZAZP_ASSIGNMENT"]

  Z01 -->|"validate_rule"| VAL2
  Z01 -->|"simulate_month"| GEN2
  SM -->|"validate_rule_ctx<br/>validate_daily<br/>validate_break"| VAL2

  ZBP2 -->|"Validations / simulateMonth"| VAL2
  ZBP2 -->|"simulateMonth"| GEN2
  ZBP2 -->|"save / copyAsTemplate"| PER2
  ZBP2 -->|"ensure + record keys"| TRN2

  PER2 -->|"validate_rule_ctx vor Write"| VAL2
  PER2 -->|"CTS-Keys"| TRN2

  ASN2 -.->|"noch ohne Caller"| PA0007["PA0007"]
```

### Rollen der Klassen

| Klasse | Aufgabe | Wird gerufen von |
|---|---|---|
| **VALIDATION** | Plausibilität Regel / Tagesplan / Pause | ZAZP01, SM30, RAP, PERSIST |
| **PERSIST** | Schreiben/Löschen Customizing + Textte | RAP-Saver, Action `copyAsTemplate` |
| **TRANSPORT** | Offenen Customizing-Auftrag sichern, TABU-Keys | PERSIST, RAP-Saver |
| **GENERATION** | Monatssimulation (nur Lesen/Rechnen) | ZAZP01, RAP-Action `simulateMonth` |
| **ASSIGNMENT** | IT0007 zuordnen (`HR_MAINTAIN_MASTERDATA`) | RAP `assignEmployee` / Fiori-Dialog; GUI: `PA30` |

Unter den `ZCL_ZAZP_*`-Klassen gibt es nur diese Abhängigkeiten:

```text
PERSIST  →  VALIDATION, TRANSPORT
VALIDATION / TRANSPORT / GENERATION / ASSIGNMENT  →  (keine anderen ZCL_ZAZP_*)
```

---

## 3. Einstiege im Detail

### 3.1 Transaktion `ZAZP01`

```mermaid
sequenceDiagram
  actor User
  participant R as Report ZAZP01
  participant V as ZCL_ZAZP_VALIDATION
  participant G as ZCL_ZAZP_GENERATION
  participant DB as T508A / T551A / T550A / T550P

  User->>R: SCHKZ + Gruppierungen + Monat
  opt Validierung aktiv
    R->>V: validate_rule
    V->>DB: SELECT Regelkette
    V-->>R: Messages
  end
  opt Simulation aktiv
    R->>G: simulate_month
    G->>DB: SELECT + Feiertage
    G-->>R: Tagesliste
  end
```

### 3.2 SM30-Events (FUGR `ZAZP_SM30`)

| View | Form | Aufruf |
|---|---|---|
| `V_T508A` | `ZAZP_VALIDATE_T508A` | `validate_rule_ctx` |
| `V_T551A` | `ZAZP_VALIDATE_T551A` | Parent `T508A` laden → `validate_rule_ctx` |
| `V_T550A` | `ZAZP_VALIDATE_T550A` | `validate_daily` |
| `V_T550P` | `ZAZP_VALIDATE_T550P` | `validate_break` |

### 3.3 Fiori / RAP

```mermaid
flowchart TB
  APP["app/azp-workschedulerule<br/>List Report + Object Page"]
  ODATA["OData V4<br/>ZUI_ZAZP_RULE_UI"]
  LHC["lhc_rule<br/>Validations + Actions"]
  LSC["lsc_* Saver<br/>save_modified"]

  APP --> ODATA --> LHC
  ODATA --> LSC

  LHC -->|"valWeekSum"| V["VALIDATION.validate_rule_ctx"]
  LHC -->|"valTimeframe"| Vd["VALIDATION.validate_daily"]
  LHC -->|"valBreaks"| Vb["VALIDATION.validate_break"]
  LHC -->|"simulateMonth"| G["GENERATION.simulate_month"]
  LHC -->|"copyAsTemplate"| P["PERSIST.save_rule"]
  LHC -->|"copyAsTemplate"| T["TRANSPORT.ensure_…"]

  LSC -->|"Root C/U"| P
  LSC -->|"Root D"| Pd["PERSIST.delete_rule"]
  LSC -->|"Child C/U/D"| TAB["MODIFY/DELETE<br/>T551A · T550A · T550P"]
  LSC --> T
```

---

## 4. RAP Business Object (Composition)

```mermaid
flowchart TB
  ROOT["ZI_ZAZP_WorkScheduleRule<br/>(T508A) · managed + unmanaged save + draft"]

  ROOT -->|composition| W["_Weeks<br/>ZI_ZAZP_WeekPattern · T551A"]
  ROOT -->|composition| D["_DailySchedules<br/>ZI_ZAZP_DailyWorkSchedule · T550A"]
  ROOT -->|composition| B["_BreakSchedules<br/>ZI_ZAZP_BreakSchedule · T550P"]
  ROOT -->|association| A["_Assignments<br/>ZI_ZAZP_EmployeeAssignment · PA0007"]
  ROOT -->|association| TXT["_Text<br/>ZI_ZAZP_RuleText · T508S"]

  PROJ["Projektion ZC_ZAZP_WorkScheduleRule<br/>+ ZC_*-Children"]
  ROOT -.-> PROJ
```

| Element | Bedeutung |
|---|---|
| **Root-Key** | `EsGrouping / HolidayCalendarId / PsGrouping / RuleId / ValidTo` (= T508A-PK) |
| **Draft** | `ZAZP_D_RULE` / `_WEEK` / `_DAILY` / `_BREAK` |
| **Actions** | `copyAsTemplate`, `simulateMonth` |
| **Service** | Rule, Week, Daily, Break, EmployeeAssignment, HolidayCalendar |

---

## 5. Datenzugriff je Klasse

```mermaid
flowchart LR
  subgraph Classes
    VAL["VALIDATION"]
    PER["PERSIST"]
    GEN["GENERATION"]
    TRN["TRANSPORT"]
    ASN["ASSIGNMENT"]
  end

  T508A["T508A / T508S"]
  T551A["T551A"]
  T550A["T550A / T550S"]
  T550P["T550P"]
  PA7["PA0007"]
  E07["E070 / E07T"]

  VAL -->|R| T508A
  VAL -->|R| T551A
  VAL -->|R| T550A
  VAL -->|R| T550P

  PER -->|R/W/D| T508A
  PER -->|W| T551A
  PER -->|W| T550A
  PER -->|W| T550P

  GEN -->|R| T508A
  GEN -->|R| T551A
  GEN -->|R| T550A

  TRN -->|R/W| E07
  ASN -->|R/W| PA7
  ASN -->|R| T508A
```

**Objektkette (fachlich):**

```text
PA0007.SCHKZ → T508A.SCHKZ → T508A.ZMODN → T551A
                                          → T550A → T550P
```

---

## 6. Kurz: Weg A vs. Weg B

| Weg | Was | Wer |
|---|---|---|
| **A – Customizing** | Regel + Wochen + Tagespläne + Pausen pflegen | GUI/SM30/Fiori → VALIDATION + PERSIST + TRANSPORT |
| **B – Zuordnung** | Mitarbeiter (IT0007) einer Regel zuweisen | `ASSIGNMENT` + RAP/Fiori verdrahtet |

---

## 7. Repo-Spiegel

| Pfad | Inhalt |
|---|---|
| [`sap/clas/`](../../sap/clas/) | `ZCL_ZAZP_*`, `ZBP_I_ZAZP_WORKSCHEDULERULE` |
| [`sap/prog/`](../../sap/prog/) | `ZAZP01`, SM30-Includes |
| [`sap/ddls/`](../../sap/ddls/) · [`bdef/`](../../sap/bdef/) · [`srvd/`](../../sap/srvd/) | CDS / Behavior / Service |
| [`app/azp-workschedulerule/`](../../app/azp-workschedulerule/) | Fiori Elements App |
