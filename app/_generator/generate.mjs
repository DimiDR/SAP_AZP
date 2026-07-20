import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, "../..");
const appParent = resolve(root, "app");
const edmx = readFileSync(join(__dirname, "metadata.xml"), "utf8");

const config = {
  version: "0.2",
  floorplan: "FE_LROP",
  project: {
    name: "azp-workschedulerule",
    title: "Arbeitszeitpläne",
    description: "AZP Arbeitszeitplanregeln pflegen (Fiori Elements)",
    targetFolder: appParent.replace(/\\/g, "/"),
    ui5Version: "1.132.1",
    localUI5Version: "1.132.1",
    sapux: true,
  },
  service: {
    host: "https://localhost",
    servicePath:
      "/sap/opu/odata4/sap/zui_zazp_rule_o4/srvd_a2x/sap/zui_zazp_workschedulerule/0001/",
    client: "100",
    edmx,
  },
  entityConfig: {
    mainEntity: {
      entityName: "WorkScheduleRule",
    },
    navigationEntity: {
      entityName: "_Weeks",
    },
    generateFormAnnotations: false,
    generateLROPAnnotations: false,
  },
  telemetryData: {
    generationSourceName: "AZP_UI",
    generationSourceVersion: "1.0.0",
  },
};

mkdirSync(__dirname, { recursive: true });
const configPath = join(__dirname, "generator-config.json");
writeFileSync(configPath, JSON.stringify(config, null, 2), "utf8");

console.log("Running @sap/generator-fiori headless…");
const result = spawnSync(
  "npx",
  [
    "-y",
    "yo@4.3.1",
    "@sap/fiori:headless",
    configPath,
    "--force",
    "--skipInstall",
  ],
  {
    cwd: root,
    stdio: "inherit",
    shell: true,
    env: { ...process.env, npm_config_yes: "true" },
  }
);

process.exit(result.status ?? 1);
