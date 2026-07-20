# AZP-Tool – ABAP-Objektliste (Umsetzungs-Checkliste)

> Alle anzulegenden ABAP-/RAP-Objekte für die Lösung „Logik in SAP (ABAP/RAP)".
> **Paket durchgängig: `ZAZP_HR_TIME`** (Kunden-Z-Namensraum). Daten bleiben in den Standardtabellen
> `T508A/T551A/T550A/T550P/PA0007` – keine Z-Datentabellen.
> Bezug: [`AZP-CDS-Datenmodell.md`](AZP-CDS-Datenmodell.md),
> [`AZP-Service-Schicht.md`](AZP-Service-Schicht.md),
> [`AZP-Transport-Service-Spezifikation.md`](AZP-Transport-Service-Spezifikation.md).
> Legende: ☐ offen · ◐ in Arbeit · ☑ fertig. Stand: 2026-07-19 (Web-UI inkl. Deep Create aktiv)

---

## 1. Paket & Grundobjekte

| ☐ | Objekt | Typ | Zweck |
|---|---|---|---|
| ☑ | `ZAZP_HR_TIME` | Paket (DEVC) | Entwicklungspaket, Transportschicht zuordnen |
| ◐ | `ZAZP` | Nachrichtenklasse (SE91) | Klasse da; Texte manuell in SE91 (siehe Implementierungsstand) |

---

## 2. DDIC – Draft-Tabellen (nur Fiori-Draft)

> Nur technische Draft-Persistenz für RAP; Aktivdaten bleiben in den Standardtabellen.

| ☐ | Objekt | Typ | Zweck |
|---|---|---|---|
| ☑ | `ZAZP_D_RULE` | Tabelle (TABL) | Draft: Arbeitszeitplanregel |
| ☑ | `ZAZP_D_WEEK` | Tabelle (TABL) | Draft: Wochenmuster (Composition-Kind) |
| ☑ | `ZAZP_D_DAILY` | Tabelle (TABL) | Draft: Tagesplan (Composition-Kind) |
| ☑ | `ZAZP_D_BREAK` | Tabelle (TABL) | Draft: Pausenplan (Composition-Kind) |

---

## 3. CDS – Interface-Views `ZI_ZAZP_*` (über Standardtabellen)

| ☐ | Objekt | Typ | Quelle |
|---|---|---|---|
| ☑ | `ZI_ZAZP_WorkScheduleRule` | CDS View Entity (root) | `T508A` + Composition Weeks/Daily/Break |
| ☑ | `ZI_ZAZP_RuleText` | CDS View Entity | `T508S` |
| ☑ | `ZI_ZAZP_WeekPattern` | CDS View Entity | `T551A` (to parent) |
| ☑ | `ZI_ZAZP_DailyWorkSchedule` | CDS View Entity | `T550A` (to parent) |
| ☑ | `ZI_ZAZP_DailyWorkScheduleText` | CDS View Entity | `T550S` |
| ☑ | `ZI_ZAZP_BreakSchedule` | CDS View Entity | `T550P` (to parent) |
| ☑ | `ZI_ZAZP_EmployeeAssignment` | CDS View Entity | `PA0007` |
| ☑ | `ZI_ZAZP_HolidayCalendar` | CDS View Entity (Wertehilfe) | Feiertagskalender (SCAL) |

---

## 4. CDS – Access Control (DCL)

| ☐ | Objekt | Typ | Zweck |
|---|---|---|---|
| ◐ | `ZI_ZAZP_WorkScheduleRule` | Access Control (DCL) | aktiv, noch offenes `grant select` |
| ◐ | `ZI_ZAZP_DailyWorkSchedule` | Access Control (DCL) | aktiv, noch offenes `grant select` |
| ◐ | `ZI_ZAZP_BreakSchedule` | Access Control (DCL) | aktiv, noch offenes `grant select` |

> Absicherung mit `aspect pfcg_auth` / Auth-Objekt folgt mit PFCG-Rollen (P2 #14).

---

## 5. CDS – Projektionen & UI (Fiori)

| ☐ | Objekt | Typ | Zweck |
|---|---|---|---|
| ☑ | `ZC_ZAZP_WorkScheduleRule` | CDS Projection View (root) | OData/Fiori Regel |
| ☑ | `ZC_ZAZP_WeekPattern` | CDS Projection View | OData/Fiori Wochenmuster |
| ☑ | `ZC_ZAZP_DailyWorkSchedule` | CDS Projection View | OData/Fiori Tagesplan |
| ☑ | `ZC_ZAZP_BreakSchedule` | CDS Projection View | OData/Fiori Pausenplan |
| ☑ | `ZC_ZAZP_EmployeeAssignment` | CDS Projection View | OData/Fiori Zuordnung |
| ☑ | `ZC_ZAZP_WorkScheduleRule` | Metadata Extension (DDLX) | List Report / Object Page + Facetten |
| ☑ | `ZC_ZAZP_WeekPattern` | Metadata Extension (DDLX) | Wochenmuster LineItem |
| ☑ | `ZC_ZAZP_DailyWorkSchedule` | Metadata Extension (DDLX) | Tagesplan LineItem |
| ☑ | `ZC_ZAZP_BreakSchedule` | Metadata Extension (DDLX) | Pausen LineItem |

---

## 6. CDS – Abstrakte Entitäten (Aktionsparameter/-ergebnisse)

| ☐ | Objekt | Typ | Zweck |
|---|---|---|---|
| ☑ | `ZA_ZAZP_CopyParams` | CDS Abstract Entity | Parameter `copyAsTemplate` |
| ☑ | `ZA_ZAZP_MonthParams` | CDS Abstract Entity | Parameter `simulateMonth` |
| ☑ | `ZI_ZAZP_SimDay` | CDS Abstract Entity | Ergebniszeile Simulation |

---

## 7. RAP – Behavior & Service

| ☐ | Objekt | Typ | Zweck |
|---|---|---|---|
| ☑ | `ZI_ZAZP_WorkScheduleRule` | Behavior Definition (BDEF) | unmanaged save, Draft, Deep Create, Actions |
| ☑ | `ZBP_I_ZAZP_WORKSCHEDULERULE` | Behavior Pool (Klasse) | Validierungen + Saver (Root + Children) |
| ☑ | `ZC_ZAZP_WorkScheduleRule` | Behavior Definition (Projection) | transactional_query + draft + create children |
| ☑ | `ZUI_ZAZP_WORKSCHEDULERULE` | Service Definition | exponierte Entitäten |
| ☑ | `ZUI_ZAZP_RULE_O4` | Service Binding (OData V4 – Web API) | published via `/IWFND/V4_ADMIN` |
| ☑ | `ZUI_ZAZP_RULE_UI` | Service Binding (OData V4 – UI) | published; primäre App-URL |

---

## 8. ABAP-Klassen – Logik (UI-unabhängig, von RAP **und** SM30 genutzt)

| ☐ | Objekt | Typ | Zweck |
|---|---|---|---|
| ☑ | `ZIF_ZAZP_VALIDATION` | Interface | inkl. `validate_rule_ctx` / `ty_rule_ctx` |
| ☑ | `ZCL_ZAZP_VALIDATION` | Klasse | zentrale Plausibilität (Payload + DB) |
| ☑ | `ZCL_ZAZP_GENERATION` | Klasse | Monatssimulation inkl. Feiertage |
| ☑ | `ZCL_ZAZP_PERSIST` | Klasse | Save/Delete + Transportauszeichnung |
| ☑ | `ZCL_ZAZP_TRANSPORT` | Klasse | CTS inkl. `ensure_customizing_request` |
| ☑ | `ZCL_ZAZP_ASSIGNMENT` | Klasse | Weg B: IT0007 via `HR_MAINTAIN_MASTERDATA` |

---

## 9. SAP GUI – SM30-Events & Transaktion

| ☐ | Objekt | Typ | Zweck |
|---|---|---|---|
| ◐ | `ZAZP_SM30` / `ZAZP_SM30_EVENTS` | FUGR + Include | Forms vorhanden; FUGR in SE80 aktivieren + SE54 anbinden |
| ☐ | Event 01 an `V_T508A` | Pflege-View-Event | SE54 → Form `ZAZP_VALIDATE_T508A` |
| ☐ | Event 01 an `V_T550A` | Pflege-View-Event | SE54 → Form `ZAZP_VALIDATE_T550A` |
| ☐ | Event 01 an `V_T550P` | Pflege-View-Event | SE54 → Form `ZAZP_VALIDATE_T550P` |
| ☐ | Event 01 an `V_T551A` | Pflege-View-Event | SE54 → Form `ZAZP_VALIDATE_T551A` |
| ✅ | `ZAZP01` | Report + TRAN | TCode `ZAZP01` → Report `ZAZP01` |

> Hinweis: Events werden an den **Standard**-Pflege-Views hinterlegt (SE54 → Environment → Modification →
> Events); die Routinen sind reine Aufrufe der Logik-Klasse – kein Regel-Code im View.

---

## 10. Berechtigungen & Fiori-Bereitstellung

| ☐ | Objekt | Typ | Zweck |
|---|---|---|---|
| ☐ | `ZAZP_VIEWER` | PFCG-Rolle | Lesen + Validieren/Simulieren |
| ☐ | `ZAZP_EDITOR` | PFCG-Rolle | zusätzlich Pflege + Kopieren |
| ☐ | `ZAZP_ADMIN` | PFCG-Rolle | zusätzlich Transport/Export + Zuordnung (Weg B) |
| ☐ | Fiori-Katalog/-Gruppe + Kachel | Launchpad Content | Intent `azpworkschedulerule` / `tile` (Inbound in `manifest.json`) |
| ☑ | `azp-workschedulerule` (UI5) | Fiori-Elements-App | List Report + Object Page unter `app/azp-workschedulerule/` |

> Standardberechtigungen zusätzlich prüfen: `S_TABU_DIS`/`S_TABU_NAM` (Tabellen), `S_TRANSPRT`
> (Transport), HR-Berechtigungen `P_ORGIN` (IT0007).

---

## 11. Umsetzungsreihenfolge (empfohlen)

1. ~~Grundlagen / Logik / CDS / RAP / Deep Create / Publish~~ → erledigt
2. Fiori-App gegen Live-Service testen (`npm start`)
3. Manuell P1: SE91 → SE93 → SE80-FUGR → SE54
4. PFCG-Rollen + DCL absichern + FLP-Kachel
5. P2 End-to-End-Tests

---

## 12. Fertig-Kriterien (Definition of Done)

- ☐ Gleiche AZP-Prüfung liefert in **SM30 und Fiori** identische Meldungen (eine Regelquelle).
- ☐ Speichern zeichnet Customizing auf einem **Transportauftrag** auf (SM30-Abfrage bzw. RAP).
- ☐ `simulateMonth` stimmt gegen eine `RPTKAL00`-Referenzgenerierung.
- ☐ IT0007-Zuordnung (Weg B) über `HR_MAINTAIN_MASTERDATA` erfolgreich.
- ☐ Rollen `ZAZP_VIEWER/EDITOR/ADMIN` greifen in beiden Zugängen.
- ☑ Deep Create (Regel + Wochen/Tages/Pausen) über Fiori Object Page möglich.
