# AZP – OData V4 Service Binding

Stand: 2026-07-19 · System S4P · Paket `ZAZP_HR_TIME`  
Objekte: SRVB `ZUI_ZAZP_RULE_O4` · SRVD `ZUI_ZAZP_WORKSCHEDULERULE`

---

## Status

| Merkmal | Wert |
|---|---|
| Binding aktiviert | ja |
| Gateway published | ja (via `/IWFND/V4_ADMIN`) |
| Binding-Typ | OData V4 – Web API |
| OAuth Scope | nicht nötig (On-Prem / Launchpad-Session) |
| Live-$metadata | OK unter der **korrekten** Service-URL (siehe unten) |

---

## Korrekte Service-URL

```text
/sap/opu/odata4/sap/zui_zazp_rule_o4/srvd_a2x/sap/zui_zazp_workschedulerule/0001/
```

| Pfadteil | Bedeutung |
|---|---|
| `zui_zazp_rule_o4` | Service Binding (SRVB) |
| `zui_zazp_workschedulerule` | Service Definition / Service Name (SRVD) |
| `0001` | Version |

Dieselbe URL steht in `app/azp-workschedulerule/webapp/manifest.json` (`sap.app.dataSources.mainService.uri`).

### Falsche URL (nicht verwenden)

```text
/sap/opu/odata4/sap/zui_zazp_rule_o4/srvd_a2x/sap/zui_zazp_rule_o4/0001/
```

Smoke-Test 2026-07-19: **HTTP 500**  
`/IWBEP/CM_V4_ANNO/036` — `Annotation SAP__capabilities.SupportedFormats is already defined for parent`.

---

## Publish: ADT vs. `/IWFND/V4_ADMIN`

Im **Customizing-Mandanten** schlägt ADT „Publish“ fehl:

> `(Un-)Publishing of SRVB … in Customizing Client not allowed`

Deshalb:

| Schritt | Wo | Was |
|---|---|---|
| 1 | ADT | Service Binding `ZUI_ZAZP_RULE_O4` **aktivieren** (nicht lokal publishen) |
| 2 | SAP GUI | Transaktion `/n/IWFND/V4_ADMIN` → **Publish Service Groups** |
| 3 | Dialog | System Alias `LOCAL`, Service Group / Binding suchen → Publish |
| 4 | Dialog | Customizing-Auftrag zuordnen |
| 5 | ADT | Binding-Editor mit **F5** refreshen |

**Hinweis:** ADT kann den „Local Service Endpoint“ weiterhin als *Unpublished* zeigen, obwohl die Servicegruppe im Gateway published ist. Maßgeblich ist `/IWFND/V4_ADMIN` bzw. ein erfolgreicher `$metadata`-Aufruf.

OAuth Scope beim Publish: **nicht** setzen (interne On-Prem-Nutzung).

Nicht verwechseln:

| Transaktion | Für |
|---|---|
| `/IWFND/V4_ADMIN` | OData **V4** Service Groups |
| `/IWFND/MAINT_SERVICE` | OData **V2** |

---

## Smoke-Test (verifiziert 2026-07-19)

ABAP Unit im Programm `$TMP` / `ZAZP_ODATA_SMOKE` (interner HTTP-GET):

| URL | HTTP |
|---|---|
| `…/sap/zui_zazp_rule_o4/0001/$metadata` | 500 |
| `…/sap/zui_zazp_workschedulerule/0001/$metadata` | **200** |

Manuell prüfen (Browser / Gateway Client, gleicher Mandant):

```text
/sap/opu/odata4/sap/zui_zazp_rule_o4/srvd_a2x/sap/zui_zazp_workschedulerule/0001/$metadata
```

---

## Web-UI Create/Edit (Stand 2026-07-19)

Auf dem **bereits published** Binding `ZUI_ZAZP_RULE_O4` sind jetzt aktiv:

| Fähigkeit | Objekt |
|---|---|
| Draft Create/Edit/Activate | Root-BDEF `ZI_ZAZP_WorkScheduleRule` + Draft-Tabelle `ZAZP_D_RULE` |
| Projection / transactional | `ZC_ZAZP_WorkScheduleRule` + Projection-BDEF |
| Actions | `copyAsTemplate`, `simulateMonth` |
| UI-Annotationen | Metadata Extension `ZC_ZAZP_WorkScheduleRule` |
| Global/Instance Auth | `%create` / `%update` / `%delete` / Draft-Edit erlaubt |

### Service Bindings

| Binding | Typ | Status |
|---|---|---|
| `ZUI_ZAZP_RULE_O4` | Web API | **published** |
| `ZUI_ZAZP_RULE_UI` | V4 UI (Fiori Elements) | **published** via `/IWFND/V4_ADMIN` |

**Primäre App-URL** (in `app/azp-workschedulerule/webapp/manifest.json`):

```text
/sap/opu/odata4/sap/zui_zazp_rule_ui/srvd_a2x/sap/zui_zazp_workschedulerule/0001/
```

### Deep Create (Stand 2026-07-19)

Composition-Children mit Draft:

| Navigation | Tabelle | Draft |
|---|---|---|
| `_Weeks` | `T551A` | `ZAZP_D_WEEK` |
| `_DailySchedules` | `T550A` | `ZAZP_D_DAILY` |
| `_BreakSchedules` | `T550P` | `ZAZP_D_BREAK` |

Object Page: Allgemein + Wochenmuster + Tagespläne + Pausen. Anlegen/Ändern im Draft → Aktivieren schreibt Standardtabellen + Transport.

**Hinweis:** Perioden-/Tages-/Pausenpläne sind in SAP oft geteilt (`MOTPR`/`ZMODN`). Änderungen an Kindern wirken für alle Regeln mit derselben Gruppierung.

### Noch offen (manuell)

- PFCG-Rollen `ZAZP_VIEWER` / `EDITOR` / `ADMIN`
- DCL von offenem `grant select` auf `aspect pfcg_auth` umstellen
- FLP-Kachel (Catalog/Group + Intent `azpworkschedulerule` / `tile`; Inbound in App-`manifest.json` vorhanden)

Siehe [AZP-Offene-ToDos.md](AZP-Offene-ToDos.md) P3.
