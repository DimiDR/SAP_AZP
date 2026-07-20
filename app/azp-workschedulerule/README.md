## Application Details
|               |
| ------------- |
|**Generation Date and Time**<br>Sun Jul 19 2026 16:24:39 GMT+0200 (Mitteleuropäische Sommerzeit)|
|**App Generator**<br>SAP Fiori Application Generator|
|**App Generator Version**<br>1.25.0|
|**Generation Platform**<br>CLI|
|**Template Used**<br>List Report Page V4|
|**Service Type**<br>OData URL|
|**Service URL**<br>https://localhost/sap/opu/odata4/sap/zui_zazp_rule_ui/srvd_a2x/sap/zui_zazp_workschedulerule/0001/|
|**Module Name**<br>azp-workschedulerule|
|**Application Title**<br>Arbeitszeitpläne|
|**Namespace**<br>|
|**UI5 Theme**<br>sap_horizon|
|**UI5 Version**<br>1.132.1|
|**Enable TypeScript**<br>False|
|**Add Eslint configuration**<br>True, see https://www.npmjs.com/package/@sap-ux/eslint-plugin-fiori-tools#rules for the eslint rules.|
|**Main Entity**<br>WorkScheduleRule|
|**Navigation Entity**<br>None|

## azp-workschedulerule

Fiori Elements **List Report + Object Page** für AZP-Arbeitszeitplanregeln (`ZUI_ZAZP_WORKSCHEDULERULE`).

Entspricht dem Zielbild in `docu/fachlich/AZP-Frontend-Dokumentation.md`: Filterleiste, Status-Criticality, Object-Page-Sections für Allgemein, Wochenmuster, Tagespläne, Pausen und Mitarbeiterzuordnung.

### Lokal mit Mockdaten starten

```bash
cd app/azp-workschedulerule
npm install
npm run start-mock
```

FLP-Sandbox: Intent `azpworkschedulerule-tile`, Theme `sap_horizon`.

Mockdaten liegen unter `webapp/localService/mainService/data/` (Beispiele GLZ38, TZ232, SCH3W).

### Anbindung an SAP

Service Binding `ZUI_ZAZP_RULE_UI` ist via `/IWFND/V4_ADMIN` published. RAP unterstützt Draft-Create/Edit sowie Actions `copyAsTemplate` und `simulateMonth`.

**Korrekte OData-URL** (in `webapp/manifest.json`):

```text
/sap/opu/odata4/sap/zui_zazp_rule_ui/srvd_a2x/sap/zui_zazp_workschedulerule/0001/
```

Fallback (ebenfalls published): `…/zui_zazp_rule_o4/…`. Details: `docu/technisch/AZP-OData-V4-Service.md`.

`ui5.yaml` Backend-URL auf das System zeigen und `npm start` nutzen.

**Anlegen live:** List Report → Anlegen → Schlüssel + Periodenfelder → Facetten **Wochenmuster / Tagespläne / Pausen** befüllen → Aktivieren (schreibt `T508A`/`T551A`/`T550A`/`T550P` inkl. Transport).

### Neu generieren (optional)

`app/_generator/` ist **nicht** nötig zum Starten oder Weiterentwickeln. Nur wenn die App aus dem OData-EDMX neu gescaffoldet werden soll:

```bash
node app/_generator/generate.mjs
```

#### Pre-requisites

1. Active NodeJS LTS and matching npm (see https://nodejs.org)


