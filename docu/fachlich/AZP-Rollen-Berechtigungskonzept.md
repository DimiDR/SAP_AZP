# AZP-Tool – Rollen- & Berechtigungskonzept

> Berechtigungskonzept für die ABAP/RAP-Lösung. Deckt beide Zugänge ab: **SAP GUI** (SM30/`SPRO`,
> Transaktion `ZAZP01`) und die **optionale Fiori-UI** (RAP/OData). Bezug:
> [`AZP-ABAP-Objektliste.md`](../technisch/AZP-ABAP-Objektliste.md),
> [`AZP-Service-Schicht.md`](../technisch/AZP-Service-Schicht.md). Stand: 2026-07-17

---

## 1. Rollenmodell

Drei aufeinander aufbauende PFCG-Rollen:

| Rolle | Zweck |
|---|---|
| `ZAZP_VIEWER` | Anzeigen, Validieren, Simulieren |
| `ZAZP_EDITOR` | + AZP pflegen, Weg A (Customizing schreiben + Transport) |
| `ZAZP_ADMIN` | + Weg B (Mitarbeiterzuordnung IT0007), Transportfreigabe, Sonderrechte |

Aufbauend = `ZAZP_EDITOR` enthält `ZAZP_VIEWER`, `ZAZP_ADMIN` enthält `ZAZP_EDITOR` (Sammelrolle oder
additive Einzelrollen). **Weg B** (Personalstammdaten) kann alternativ an eine **eigene HR-Rolle**
delegiert werden – siehe §4.4.

---

## 2. Aktivitäts-/Rollenmatrix

| Aktivität | VIEWER | EDITOR | ADMIN |
|---|:--:|:--:|:--:|
| AZP anzeigen | ✔ | ✔ | ✔ |
| Validieren / Monat simulieren | ✔ | ✔ | ✔ |
| AZP pflegen (anlegen/ändern/löschen) | – | ✔ | ✔ |
| Kopieren als Vorlage | – | ✔ | ✔ |
| Transport wählen / neu anlegen | – | ✔ | ✔ |
| In SAP übernehmen (Weg A, Customizing) | – | ✔ | ✔ |
| Mitarbeiter zuordnen (Weg B, IT0007) | – | – | ✔ |
| Transportauftrag freigeben | – | – | ✔ |

---

## 3. Berechtigungsobjekte je Rolle (Überblick)

| Objekt | Zweck | VIEWER | EDITOR | ADMIN |
|---|---|:--:|:--:|:--:|
| `S_TCODE` | Transaktions-/Zugangsstart | Anzeige | Pflege | + Weg B/Transport |
| `S_SERVICE` | OData-Service / Fiori-Start | ✔ | ✔ | ✔ |
| `S_TABU_NAM` | Tabellenpflege (tabellengenau) | 03 | 02/03 | 02/03 |
| `S_TABU_DIS` | Tabellenpflege (Gruppe) | 03 | 02/03 | 02/03 |
| `S_TRANSPRT` | Transportaufträge | – | 01/02 | 01/02/43 |
| `P_ORGIN` | HR-Stammdaten IT0007 (Weg B) | – | – | R/W |

Details der Feldwerte in §4.

---

## 4. Berechtigungsobjekte im Detail

### 4.1 Tabellenpflege – `S_TABU_NAM` (empfohlen, tabellengenau)

Steuert die Pflege **genau** der AZP-Tabellen, unabhängig von der Tabellen-Berechtigungsgruppe:

| Feld | VIEWER | EDITOR / ADMIN |
|---|---|---|
| `TABLE` | `T508A`,`T508S`,`T550A`,`T550S`,`T550P`,`T551A` | dieselben |
| `ACTVT` | `03` (Anzeigen) | `02` (Ändern), `03` (Anzeigen) |

### 4.2 Tabellenpflege – `S_TABU_DIS` (Gruppenebene, zusätzlich)

| Feld | Wert |
|---|---|
| `DICBERCLS` | **Berechtigungsgruppe der AZP-Tabellen – im System ermitteln** (siehe §7) |
| `ACTVT` | `03` (VIEWER) · `02`+`03` (EDITOR/ADMIN) |

> `S_TABU_DIS` und `S_TABU_NAM` wirken zusammen (ODER-Verknüpfung im Standard). Für ein präzises Konzept
> genügt `S_TABU_NAM`; `S_TABU_DIS` nur ergänzen, wenn Gruppensteuerung gewünscht ist.

### 4.3 Transport – `S_TRANSPRT`

| Feld | EDITOR | ADMIN |
|---|---|---|
| `TTYPE` | `CUST` (Customizing-Auftrag/-Aufgabe) | `CUST` |
| `ACTVT` | `01` (Anlegen), `02` (Ändern) | `01`,`02`,`43` (Freigeben) |

### 4.4 HR-Stammdaten IT0007 – `P_ORGIN` (nur Weg B / ADMIN)

| Feld | Wert |
|---|---|
| `INFTY` | `0007` (Planned Working Time) |
| `SUBTY` | `*` (bzw. eingrenzen) |
| `AUTHC` | `R` (lesen) und `W` (schreiben) |
| `PERSA` | Personalbereiche (nach Zuständigkeit) |
| `PERSG` / `PERSK` | Mitarbeiter(teil)gruppen (nach Zuständigkeit) |
| `VDSK1` | Organisationsschlüssel (optional) |

> Bei kontextabhängiger Berechtigung stattdessen `P_ORGINCON`. Da dies echte Personalstammdaten betrifft,
> sollte Weg B organisatorisch ggf. an eine **dedizierte HR-Rolle** gehen statt an `ZAZP_ADMIN`.

### 4.5 Zugangsstart – `S_TCODE`

| Rolle | Transaktionen |
|---|---|
| VIEWER | Fiori-Kachel; `SM30` (nur Anzeige), opt. `ZAZP01` (Anzeige) |
| EDITOR | + `ZAZP01`, `SM30`, `SPRO` |
| ADMIN | + `PA30`/`PA40` (Weg B), `SE01`/`SE09`/`SE10` (Transport) |

---

## 5. Fiori-/OData-Berechtigung

| Element | Objekt / Maßnahme |
|---|---|
| OData-V4-Service starten | `S_SERVICE` für Binding `ZUI_ZAZP_RULE_UI` (primär) bzw. `ZUI_ZAZP_RULE_O4` (Web API) — Hash in SU24/`/IWFND/V4_ADMIN` |
| Fiori-App/Kachel | Katalog + Gruppe; Intent `azpworkschedulerule` / `tile` (Inbound in `app/azp-workschedulerule/`) |
| Vorschlagswerte | `SU24` für Service/BO pflegen → `S_SERVICE`, `S_TABU_NAM`, `S_TRANSPRT` als Default |

RAP prüft beim Aufruf zusätzlich die **DCL** (§6) und die Behavior-Authorization (`authorization master`).

---

## 6. RAP-DCL-Anbindung (Zugriffssteuerung der CDS)

Die Access-Control-Objekte ([`AZP-ABAP-Objektliste.md`](../technisch/AZP-ABAP-Objektliste.md) §4) verknüpfen die Interface-Views mit einem
Berechtigungsobjekt:

```abap
@EndUserText.label: 'AZP: Zugriff Arbeitszeitplanregel'
@MappingRole: true
define role ZI_ZAZP_WorkScheduleRule {
  grant select on ZI_ZAZP_WorkScheduleRule
    where ( RuleId ) = aspect pfcg_auth ( S_TABU_NAM, ACTVT = '03' );
    // bzw. kundeneigenes Objekt ZAZP (§8) für Gruppierungs-Einschränkung
}
```

So gilt in **Fiori** dieselbe Einschränkung wie in SAP GUI (SM30) – konsistent zur geteilten Logik.

---

## 7. Im System zu ermitteln

| Punkt | Wo | Anmerkung |
|---|---|---|
| Tabellen-Berechtigungsgruppe (`DICBERCLS`) der AZP-Tabellen | `SE54` → Berechtigungsgruppen, bzw. Tabelle `TDDAT` (Feld `CCLASS`) für `T508A/T550A/T550P/T551A` | Für `S_TABU_DIS`. **Live-Auslesung war beim Erstellen nicht verfügbar** – nachziehen. Umgehung: `S_TABU_NAM` (§4.1) |
| Service-Hash `S_TABU`/`S_SERVICE` | `SU24`/`/IWFND/MAINT_SERVICE` bzw. Service-Binding | nach Aktivierung des OData-Service |
| Personalbereiche/-gruppen für `P_ORGIN` | HR-Organisation | nach Zuständigkeit der AZP-Pflege |

---

## 8. Optional: kundeneigenes Objekt `ZAZP` (Gruppierungs-Einschränkung)

Wenn die Pflege **nach Gruppierung** (Personalteilbereich/Tagesplan-Gruppierung) eingeschränkt werden
soll, statt nur nach Tabelle:

| Auth-Objekt `ZAZP` | Feld | Werte |
|---|---|---|
|  | `ACTVT` | `03` Anzeigen · `02` Ändern |
|  | `MOSID` | PS-Gruppierung (aus `T508A`) |
|  | `MOTPR` | Tagesplan-Gruppierung |

Einzubinden in die DCL (§6, statt `S_TABU_NAM`) **und** in die SM30-Event-Prüfung (`ZCL_ZAZP_VALIDATION`
bzw. eigene Auth-Prüfung) – damit die Einschränkung wieder in **beiden** Zugängen identisch wirkt.

---

## 9. Definition of Done (Berechtigungen)

- ☐ `ZAZP_VIEWER/EDITOR/ADMIN` angelegt, Menü + Berechtigungsobjekte gepflegt, generiert.
- ☐ Anzeige/Pflege/Transport greifen in **SM30 und Fiori** identisch (DCL + S_TABU konsistent).
- ☐ Weg B (IT0007) nur mit `P_ORGIN` (W) möglich; ohne → sauberer Fehler, kein Datenschreiben.
- ☐ `S_TABU_DIS`-Gruppe ergänzt **oder** bewusst auf `S_TABU_NAM` verzichtet und dokumentiert.
- ☐ `SU24`-Vorschlagswerte für den OData-Service gepflegt.
