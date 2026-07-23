sap.ui.define(
	[
		"sap/ui/model/json/JSONModel",
		"sap/ui/model/Filter",
		"sap/ui/model/FilterOperator",
		"sap/m/MessageBox",
		"sap/m/MessageToast",
		"sap/m/SelectDialog",
		"sap/m/StandardListItem"
	],
	function (
		JSONModel,
		Filter,
		FilterOperator,
		MessageBox,
		MessageToast,
		SelectDialog,
		StandardListItem
	) {
		"use strict";

		var NS =
			"com.sap.gateway.srvd_a2x.zui_zazp_workschedulerule.v0001";
		var ACTION_READ = NS + ".readEmployeeAssignment";
		var ACTION_ASSIGN = NS + ".assignEmployee";
		var ENTITY_SET = "/WorkScheduleRule";
		var ASG_ENTITY_SET = "/EmployeeAssignment";
		var NAV_MODEL = "azpAssignNav";

		function todayIso() {
			var d = new Date();
			var m = String(d.getMonth() + 1).padStart(2, "0");
			var day = String(d.getDate()).padStart(2, "0");
			return d.getFullYear() + "-" + m + "-" + day;
		}

		function padPernr(s) {
			s = String(s || "").replace(/\D/g, "");
			if (!s) {
				return "";
			}
			return s.padStart(8, "0");
		}

		function t(oBundle, sKey, sFallback) {
			if (oBundle && oBundle.hasText(sKey)) {
				return oBundle.getText(sKey);
			}
			return sFallback || sKey;
		}

		function getModel(oExtensionAPI) {
			if (oExtensionAPI && typeof oExtensionAPI.getModel === "function") {
				return oExtensionAPI.getModel();
			}
			return null;
		}

		function getI18n(oExtensionAPI) {
			try {
				var oView =
					oExtensionAPI &&
					typeof oExtensionAPI.getView === "function" &&
					oExtensionAPI.getView();
				return (
					oView &&
					oView.getModel("i18n") &&
					oView.getModel("i18n").getResourceBundle()
				);
			} catch (e) {
				return null;
			}
		}

		function getAppComponent(oExtensionAPI) {
			try {
				if (
					oExtensionAPI &&
					typeof oExtensionAPI.getAppComponent === "function"
				) {
					var oDirect = oExtensionAPI.getAppComponent();
					if (oDirect) {
						return oDirect;
					}
				}
				var oView =
					oExtensionAPI &&
					typeof oExtensionAPI.getView === "function" &&
					oExtensionAPI.getView();
				if (!oView) {
					return null;
				}
				var oCtrl = oView.getController && oView.getController();
				if (oCtrl && typeof oCtrl.getAppComponent === "function") {
					var oFromCtrl = oCtrl.getAppComponent();
					if (oFromCtrl) {
						return oFromCtrl;
					}
				}
				var oComp = sap.ui.core.Component.getOwnerComponentFor(oView);
				while (oComp) {
					if (oComp.isA && oComp.isA("sap.fe.core.AppComponent")) {
						return oComp;
					}
					if (
						typeof oComp.getRouter === "function" &&
						oComp.getRouter() &&
						typeof oComp.getManifestEntry === "function"
					) {
						var oRoutingCfg = oComp.getManifestEntry("sap.ui5/routing");
						if (
							oRoutingCfg &&
							oRoutingCfg.routes &&
							oRoutingCfg.routes.some(function (r) {
								return r.name === "AssignmentPage";
							})
						) {
							return oComp;
						}
					}
					oComp =
						typeof oComp.getOwnerComponent === "function"
							? oComp.getOwnerComponent()
							: null;
				}
			} catch (e) {
				return null;
			}
			return null;
		}

		function selectedRuleId(oExtensionAPI, aSelectedContexts) {
			var aCtx = aSelectedContexts;
			if ((!aCtx || !aCtx.length) && oExtensionAPI) {
				if (typeof oExtensionAPI.getSelectedContexts === "function") {
					aCtx =
						oExtensionAPI.getSelectedContexts("worklistTable") ||
						oExtensionAPI.getSelectedContexts() ||
						[];
				}
			}
			if (aCtx && aCtx.length >= 1 && aCtx[0].getObject) {
				var o = aCtx[0].getObject() || {};
				return o.RuleId || o.ruleId || "";
			}
			if (
				oExtensionAPI &&
				typeof oExtensionAPI.getBindingContext === "function"
			) {
				var oBc = oExtensionAPI.getBindingContext();
				if (oBc && oBc.getObject) {
					var oRoot = oBc.getObject() || {};
					return oRoot.RuleId || oRoot.ruleId || "";
				}
			}
			return "";
		}

		function invokeStaticAction(oModel, sAction, oParams) {
			var sPath = ENTITY_SET + "/" + sAction + "(...)";
			var oActionContext = oModel.bindContext(sPath);
			Object.keys(oParams || {}).forEach(function (sKey) {
				var v = oParams[sKey];
				if (v === "" || v === undefined || v === null) {
					return;
				}
				oActionContext.setParameter(sKey, v);
			});
			return oActionContext.execute().then(function () {
				var oBound = oActionContext.getBoundContext();
				if (!oBound) {
					return null;
				}
				if (typeof oBound.requestObject === "function") {
					return oBound.requestObject().then(function (v) {
						if (Array.isArray(v)) {
							return v[0] || null;
						}
						if (v && Array.isArray(v.value)) {
							return v.value[0] || null;
						}
						return v;
					});
				}
				var vObj = oBound.getObject();
				if (Array.isArray(vObj)) {
					return vObj[0] || null;
				}
				if (vObj && Array.isArray(vObj.value)) {
					return vObj.value[0] || null;
				}
				return vObj;
			});
		}

		function normalizeResult(o) {
			if (!o) {
				return null;
			}
			return {
				pernr: o.Pernr || o.pernr || "",
				ruleId: o.RuleId || o.ruleId || "",
				validFrom: o.ValidFrom || o.validFrom || "",
				validTo: o.ValidTo || o.validTo || "",
				employmentPct:
					o.EmploymentPct != null
						? o.EmploymentPct
						: o.employmentPct,
				weeklyHours:
					o.WeeklyHours != null ? o.WeeklyHours : o.weeklyHours,
				success:
					o.Success === true ||
					o.Success === "true" ||
					o.success === true,
				message: o.MessageText || o.messageText || o.Message || ""
			};
		}

		function createPageModel(sRuleId) {
			return new JSONModel({
				busy: false,
				ruleId: sRuleId || "",
				validFrom: todayIso(),
				validTo: "9999-12-31",
				employmentPct: "",
				weeklyHours: "",
				keyDate: todayIso(),
				addPernr: "",
				message: "",
				messageType: "Information",
				employees: []
			});
		}

		function findEmployeeIndex(aEmployees, sPernr) {
			for (var i = 0; i < aEmployees.length; i++) {
				if (aEmployees[i].pernr === sPernr) {
					return i;
				}
			}
			return -1;
		}

		function addEmployee(oAsgModel, sPernr, sCurrentRuleId) {
			sPernr = padPernr(sPernr);
			if (!sPernr) {
				return false;
			}
			var aEmployees = oAsgModel.getProperty("/employees") || [];
			if (findEmployeeIndex(aEmployees, sPernr) >= 0) {
				return false;
			}
			aEmployees.push({
				pernr: sPernr,
				currentRuleId: sCurrentRuleId || "",
				statusText: "",
				statusState: "None"
			});
			oAsgModel.setProperty("/employees", aEmployees);
			return true;
		}

		function readAssignment(oModel, sPernr, sKeyDate) {
			return invokeStaticAction(oModel, ACTION_READ, {
				Pernr: padPernr(sPernr),
				KeyDate: sKeyDate || todayIso()
			}).then(normalizeResult);
		}

		function assignOne(oModel, oParams) {
			return invokeStaticAction(oModel, ACTION_ASSIGN, oParams).then(
				normalizeResult
			);
		}

		function resolveODataModel(oHost) {
			if (oHost) {
				if (typeof oHost.getAppComponent === "function") {
					var oApp = oHost.getAppComponent();
					if (oApp && oApp.getModel) {
						var oFromApp = oApp.getModel();
						if (oFromApp && oFromApp.bindList) {
							return oFromApp;
						}
					}
				}
				if (typeof oHost.getExtensionAPI === "function") {
					var oApi = oHost.getExtensionAPI();
					if (oApi && typeof oApi.getModel === "function") {
						var oFromApi = oApi.getModel();
						if (oFromApi && oFromApi.bindList) {
							return oFromApi;
						}
					}
				}
				if (typeof oHost.getView === "function") {
					var oView = oHost.getView();
					var oFromView = oView && oView.getModel && oView.getModel();
					if (oFromView && oFromView.bindList) {
						return oFromView;
					}
				}
			}
			return null;
		}

		function openPernrValueHelp(oHost, oModel, oAsgModel, oBundle, bMulti) {
			oModel = oModel && oModel.bindList ? oModel : resolveODataModel(oHost);
			if (!oModel || typeof oModel.bindList !== "function") {
				MessageBox.error(
					t(
						oBundle,
						"assignReadFailed",
						"OData-Modell nicht verfügbar."
					)
				);
				return null;
			}

			var oDialog = oHost._azpPernrVH;
			if (oDialog) {
				oDialog.destroy();
				oHost._azpPernrVH = null;
			}

			var oJsonModel = new JSONModel({
				busy: true,
				employees: []
			});

			oDialog = new SelectDialog({
				title: t(oBundle, "assignPernrSearch", "Personalnummer suchen"),
				noDataText: t(
					oBundle,
					"assignPernrSearchNoData",
					"Keine Mitarbeiter mit IT0007 gefunden."
				),
				multiSelect: !!bMulti,
				growing: true,
				growingThreshold: 100,
				busy: "{/busy}",
				busyIndicatorDelay: 0,
				liveChange: function (oEvent) {
					var sValue = String(oEvent.getParameter("value") || "").trim();
					var oBinding = oEvent.getSource().getBinding("items");
					if (!oBinding) {
						return;
					}
					if (!sValue) {
						oBinding.filter([]);
						return;
					}
					// Search only personnel numbers — never RuleId / work schedules
					var sDigits = sValue.replace(/\D/g, "") || sValue;
					oBinding.filter([
						new Filter("pernr", FilterOperator.Contains, sDigits)
					]);
				},
				confirm: function (oEvent) {
					var aItems =
						oEvent.getParameter("selectedItems") ||
						(oEvent.getParameter("selectedItem")
							? [oEvent.getParameter("selectedItem")]
							: []);
					var nAdded = 0;
					aItems.forEach(function (oItem) {
						var oCtx = oItem.getBindingContext();
						var oObj = oCtx && oCtx.getObject ? oCtx.getObject() : null;
						var sPernr = padPernr(
							(oObj && oObj.pernr) || oItem.getTitle()
						);
						var sRule = (oObj && oObj.ruleId) || "";
						if (addEmployee(oAsgModel, sPernr, sRule)) {
							nAdded++;
						}
					});
					if (nAdded > 0) {
						MessageToast.show(
							t(
								oBundle,
								"assignEmployeesAdded",
								"{0} Mitarbeiter hinzugefügt."
							).replace("{0}", String(nAdded))
						);
					}
				}
			});

			oDialog.setModel(oJsonModel);
			oDialog.bindAggregation("items", {
				path: "/employees",
				template: new StandardListItem({
					title: "{pernr}",
					description: {
						path: "ruleId",
						formatter: function (sRule) {
							return sRule
								? t(oBundle, "assignCurrent", "Aktuelle Regel") +
										": " +
										sRule
								: t(oBundle, "assignNone", "Keine aktuelle Zuordnung");
						}
					},
					type: "Active"
				}),
				templateShareable: false
			});
			oHost._azpPernrVH = oDialog;
			oDialog.open();

			// Load EmployeeAssignment explicitly (avoid inheriting WorkScheduleRule page context)
			var oListBinding = oModel.bindList(ASG_ENTITY_SET, null, null, null, {
				$select: "Pernr,RuleId,ValidFrom,ValidTo",
				$orderby: "Pernr"
			});
			oListBinding
				.requestContexts(0, 500)
				.then(function (aContexts) {
					var mSeen = {};
					var aEmployees = [];
					(aContexts || []).forEach(function (oCtx) {
						var o = (oCtx && oCtx.getObject && oCtx.getObject()) || {};
						var sPernr = padPernr(o.Pernr || o.pernr);
						if (!sPernr || mSeen[sPernr]) {
							return;
						}
						mSeen[sPernr] = true;
						aEmployees.push({
							pernr: sPernr,
							ruleId: o.RuleId || o.ruleId || "",
							validFrom: o.ValidFrom || o.validFrom || "",
							validTo: o.ValidTo || o.validTo || ""
						});
					});
					oJsonModel.setProperty("/employees", aEmployees);
					oJsonModel.setProperty("/busy", false);
					if (!aEmployees.length) {
						MessageToast.show(
							t(
								oBundle,
								"assignPernrSearchNoData",
								"Keine Mitarbeiter mit IT0007 gefunden."
							)
						);
					}
				})
				.catch(function (oErr) {
					oJsonModel.setProperty("/busy", false);
					MessageBox.error(
						(oErr && oErr.message) ||
							t(
								oBundle,
								"assignReadFailed",
								"Mitarbeiterliste konnte nicht geladen werden."
							)
					);
				});

			return oDialog;
		}

		function openRuleValueHelp(oHost, oModel, oAsgModel, oBundle) {
			oModel = oModel && oModel.bindList ? oModel : resolveODataModel(oHost);
			if (!oModel || typeof oModel.bindList !== "function") {
				MessageBox.error(
					t(
						oBundle,
						"assignReadFailed",
						"OData-Modell nicht verfügbar."
					)
				);
				return null;
			}

			var oDialog = oHost._azpRuleVH;
			if (oDialog) {
				oDialog.destroy();
				oHost._azpRuleVH = null;
			}

			var oJsonModel = new JSONModel({
				busy: true,
				rules: []
			});

			oDialog = new SelectDialog({
				title: t(oBundle, "assignRuleSearch", "Ziel-AZP suchen"),
				noDataText: t(
					oBundle,
					"assignRuleSearchNoData",
					"Keine Arbeitszeitpläne gefunden."
				),
				growing: true,
				growingThreshold: 100,
				busy: "{/busy}",
				busyIndicatorDelay: 0,
				liveChange: function (oEvent) {
					var sValue = String(oEvent.getParameter("value") || "")
						.trim()
						.toUpperCase();
					var oBinding = oEvent.getSource().getBinding("items");
					if (!oBinding) {
						return;
					}
					if (!sValue) {
						oBinding.filter([]);
						return;
					}
					oBinding.filter(
						new Filter({
							filters: [
								new Filter("ruleId", FilterOperator.Contains, sValue),
								new Filter(
									"description",
									FilterOperator.Contains,
									sValue
								)
							],
							and: false
						})
					);
				},
				confirm: function (oEvent) {
					var oItem = oEvent.getParameter("selectedItem");
					if (!oItem) {
						return;
					}
					var oCtx = oItem.getBindingContext();
					var oObj = oCtx && oCtx.getObject ? oCtx.getObject() : null;
					var sRule = String(
						(oObj && oObj.ruleId) || oItem.getTitle() || ""
					)
						.trim()
						.toUpperCase();
					if (sRule) {
						oAsgModel.setProperty("/ruleId", sRule);
					}
				}
			});

			oDialog.setModel(oJsonModel);
			oDialog.bindAggregation("items", {
				path: "/rules",
				template: new StandardListItem({
					title: "{ruleId}",
					description: "{description}",
					info: "{status}",
					type: "Active"
				}),
				templateShareable: false
			});
			oHost._azpRuleVH = oDialog;
			oDialog.open(String(oAsgModel.getProperty("/ruleId") || "").trim());

			var oListBinding = oModel.bindList(ENTITY_SET, null, null, null, {
				$select: "RuleId,Description,Status,IsActiveEntity",
				$filter: "IsActiveEntity eq true",
				$orderby: "RuleId"
			});
			oListBinding
				.requestContexts(0, 500)
				.then(function (aContexts) {
					var aRules = (aContexts || []).map(function (oCtx) {
						var o = (oCtx && oCtx.getObject && oCtx.getObject()) || {};
						return {
							ruleId: String(o.RuleId || o.ruleId || "")
								.trim()
								.toUpperCase(),
							description: o.Description || o.description || "",
							status: o.Status || o.status || ""
						};
					}).filter(function (o) {
						return !!o.ruleId;
					});
					oJsonModel.setProperty("/rules", aRules);
					oJsonModel.setProperty("/busy", false);
				})
				.catch(function (oErr) {
					// Fallback without IsActiveEntity filter (non-draft or older metadata)
					return oModel
						.bindList(ENTITY_SET, null, null, null, {
							$select: "RuleId,Description,Status",
							$orderby: "RuleId"
						})
						.requestContexts(0, 500)
						.then(function (aContexts) {
							var aRules = (aContexts || []).map(function (oCtx) {
								var o =
									(oCtx && oCtx.getObject && oCtx.getObject()) ||
									{};
								return {
									ruleId: String(o.RuleId || o.ruleId || "")
										.trim()
										.toUpperCase(),
									description:
										o.Description || o.description || "",
									status: o.Status || o.status || ""
								};
							}).filter(function (o) {
								return !!o.ruleId;
							});
							oJsonModel.setProperty("/rules", aRules);
							oJsonModel.setProperty("/busy", false);
						})
						.catch(function (oErr2) {
							oJsonModel.setProperty("/busy", false);
							MessageBox.error(
								(oErr2 && oErr2.message) ||
									(oErr && oErr.message) ||
									t(
										oBundle,
										"assignRuleSearchFailed",
										"Arbeitszeitpläne konnten nicht geladen werden."
									)
							);
						});
				});

			return oDialog;
		}

		function getFeRouting(oExtensionAPI) {
			if (!oExtensionAPI) {
				return null;
			}
			if (typeof oExtensionAPI.getRouting === "function") {
				var oViaGetter = oExtensionAPI.getRouting();
				if (oViaGetter && typeof oViaGetter.navigateToRoute === "function") {
					return oViaGetter;
				}
			}
			if (
				oExtensionAPI.routing &&
				typeof oExtensionAPI.routing.navigateToRoute === "function"
			) {
				return oExtensionAPI.routing;
			}
			return null;
		}

		function storeNavState(oApp, sRuleId) {
			var oState = {
				ruleId: sRuleId,
				openedAt: Date.now()
			};
			try {
				window.sessionStorage.setItem(
					"azpAssignNav",
					JSON.stringify(oState)
				);
			} catch (e) {
				/* ignore */
			}
			if (oApp && typeof oApp.setModel === "function") {
				oApp.setModel(new JSONModel(oState), NAV_MODEL);
			}
		}

		function readNavState(oApp) {
			if (oApp && typeof oApp.getModel === "function") {
				var oNav = oApp.getModel(NAV_MODEL);
				if (oNav && oNav.getProperty("/ruleId")) {
					return {
						ruleId: oNav.getProperty("/ruleId"),
						openedAt: oNav.getProperty("/openedAt") || 0
					};
				}
			}
			try {
				var s = window.sessionStorage.getItem("azpAssignNav");
				if (s) {
					return JSON.parse(s);
				}
			} catch (e) {
				/* ignore */
			}
			return null;
		}

		function navigateToAssignmentPage(oExtensionAPI) {
			// Prefer standard UI5 router — FE navigateToRoute is flaky for keyless custom pages
			var oApp = getAppComponent(oExtensionAPI);
			var oRouter = oApp && oApp.getRouter && oApp.getRouter();
			if (oRouter && typeof oRouter.navTo === "function") {
				try {
					oRouter.navTo("AssignmentPage");
					return Promise.resolve();
				} catch (eNav) {
					/* fall through */
				}
			}

			var oFeRouting = getFeRouting(oExtensionAPI);
			if (oFeRouting) {
				return Promise.resolve(oFeRouting.navigateToRoute("AssignmentPage"))
					.catch(function () {
						if (
							sap.ui.core &&
							sap.ui.core.routing &&
							sap.ui.core.routing.HashChanger
						) {
							sap.ui.core.routing.HashChanger.getInstance().setHash(
								"Assignment"
							);
							return;
						}
						throw new Error(
							"Kein Router für die Zuordnungsseite gefunden."
						);
					});
			}

			if (
				sap.ui.core &&
				sap.ui.core.routing &&
				sap.ui.core.routing.HashChanger
			) {
				sap.ui.core.routing.HashChanger.getInstance().setHash("Assignment");
				return Promise.resolve();
			}
			return Promise.reject(
				new Error("Kein Router für die Zuordnungsseite gefunden.")
			);
		}

		/**
		 * Custom FE action: navigate to assignment page (not a dialog).
		 * `this` === ExtensionAPI
		 */
		function onPress(oEvent, aSelectedContexts) {
			var oExtensionAPI = this;
			var oBundle = getI18n(oExtensionAPI);
			// Prefill if a rule is selected / OP context — selection is optional
			var sRuleId = selectedRuleId(oExtensionAPI, aSelectedContexts);
			storeNavState(getAppComponent(oExtensionAPI), sRuleId || "");

			return navigateToAssignmentPage(oExtensionAPI).catch(function (oErr) {
				MessageBox.error(
					(oErr && oErr.message) ||
						t(
							oBundle,
							"assignNavFailed",
							"Zuordnungsseite konnte nicht geöffnet werden."
						)
				);
			});
		}

		return {
			NAV_MODEL: NAV_MODEL,
			onPress: onPress,
			todayIso: todayIso,
			padPernr: padPernr,
			t: t,
			getModel: getModel,
			getI18n: getI18n,
			getAppComponent: getAppComponent,
			readNavState: readNavState,
			createPageModel: createPageModel,
			addEmployee: addEmployee,
			findEmployeeIndex: findEmployeeIndex,
			readAssignment: readAssignment,
			assignOne: assignOne,
			openPernrValueHelp: openPernrValueHelp,
			openRuleValueHelp: openRuleValueHelp,
			normalizeResult: normalizeResult
		};
	}
);
