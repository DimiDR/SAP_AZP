sap.ui.define(
	[
		"sap/fe/core/PageController",
		"sap/ui/core/routing/History",
		"sap/m/MessageBox",
		"sap/m/MessageToast",
		"azpworkschedulerule/ext/lib/Assignment"
	],
	function (PageController, History, MessageBox, MessageToast, Assignment) {
		"use strict";

		return PageController.extend(
			"azpworkschedulerule.ext.controller.Assignment",
			{
				onInit: function () {
					PageController.prototype.onInit.apply(this, arguments);
					this._oAsgModel = Assignment.createPageModel("");
					this.getView().setModel(this._oAsgModel, "asg");
				},

				onAfterRendering: function () {
					this._applyNavPrefill();
				},

				_bundle: function () {
					var oModel = this.getView().getModel("i18n");
					return oModel && oModel.getResourceBundle();
				},

				_odata: function () {
					var oFromApp =
						this.getAppComponent &&
						this.getAppComponent() &&
						this.getAppComponent().getModel();
					if (oFromApp && oFromApp.bindList) {
						return oFromApp;
					}
					var oApi =
						this.getExtensionAPI &&
						this.getExtensionAPI() &&
						this.getExtensionAPI().getModel &&
						this.getExtensionAPI().getModel();
					if (oApi && oApi.bindList) {
						return oApi;
					}
					return this.getView().getModel();
				},

				_applyNavPrefill: function () {
					var oApp = this.getAppComponent && this.getAppComponent();
					var oState = Assignment.readNavState(oApp);
					if (!oState) {
						return;
					}
					var nOpened = oState.openedAt || 0;
					if (nOpened && nOpened === this._nAppliedNav) {
						return;
					}
					this._nAppliedNav = nOpened;
					this._oAsgModel.setProperty("/ruleId", oState.ruleId || "");
				},

				_selectedEmployeeContexts: function () {
					var oTable = this.byId("asgEmployeeTable");
					return (oTable && oTable.getSelectedContexts()) || [];
				},

				_selectedEmployees: function () {
					return this._selectedEmployeeContexts().map(function (oCtx) {
						return oCtx.getObject();
					});
				},

				onNavBack: function () {
					if (this._azpPernrVH) {
						this._azpPernrVH.destroy();
						this._azpPernrVH = null;
					}
					if (this._azpRuleVH) {
						this._azpRuleVH.destroy();
						this._azpRuleVH = null;
					}
					var oHistory = History.getInstance();
					if (oHistory.getPreviousHash() !== undefined) {
						window.history.go(-1);
						return;
					}
					var oRouting =
						this.getExtensionAPI &&
						this.getExtensionAPI() &&
						this.getExtensionAPI().getRouting();
					if (oRouting && oRouting.navigateToRoute) {
						oRouting.navigateToRoute("WorkScheduleRuleList");
					}
				},

				onAddPernr: function (oEvent) {
					var oBundle = this._bundle();
					var sQuery =
						(oEvent && oEvent.getParameter && oEvent.getParameter("query")) ||
						this._oAsgModel.getProperty("/addPernr") ||
						"";
					var sPernr = Assignment.padPernr(sQuery);
					if (!sPernr) {
						MessageBox.error(
							Assignment.t(
								oBundle,
								"assignPernrRequired",
								"Personalnummer ist Pflicht."
							)
						);
						return;
					}
					if (!Assignment.addEmployee(this._oAsgModel, sPernr, "")) {
						MessageToast.show(
							Assignment.t(
								oBundle,
								"assignPernrDuplicate",
								"Personalnummer ist bereits in der Liste."
							)
						);
						return;
					}
					this._oAsgModel.setProperty("/addPernr", "");
					this._refreshCurrent(sPernr);
				},

				onPernrValueHelp: function () {
					var oModel = this._odata();
					var oBundle = this._bundle();
					if (!oModel) {
						MessageBox.error(
							Assignment.t(
								oBundle,
								"assignReadFailed",
								"OData-Modell nicht verfügbar."
							)
						);
						return;
					}
					Assignment.openPernrValueHelp(
						this,
						oModel,
						this._oAsgModel,
						oBundle,
						true
					);
				},

				onRuleValueHelp: function () {
					var oModel = this._odata();
					var oBundle = this._bundle();
					Assignment.openRuleValueHelp(
						this,
						oModel,
						this._oAsgModel,
						oBundle
					);
				},

				_refreshCurrent: function (sPernr) {
					var oModel = this._odata();
					var oAsg = this._oAsgModel;
					var sKeyDate = oAsg.getProperty("/keyDate");
					var aEmployees = oAsg.getProperty("/employees") || [];
					var iIdx = Assignment.findEmployeeIndex(aEmployees, sPernr);
					if (iIdx < 0 || !oModel) {
						return Promise.resolve();
					}
					return Assignment.readAssignment(oModel, sPernr, sKeyDate)
						.then(function (oRes) {
							var a = oAsg.getProperty("/employees") || [];
							var i = Assignment.findEmployeeIndex(a, sPernr);
							if (i < 0) {
								return;
							}
							a[i].currentRuleId = (oRes && oRes.ruleId) || "";
							if (!a[i].statusText) {
								a[i].statusText = "";
								a[i].statusState = "None";
							}
							oAsg.setProperty("/employees", a.slice());
						})
						.catch(function () {
							/* keep row without current rule */
						});
				},

				onReadSelected: function () {
					var oBundle = this._bundle();
					var aSelected = this._selectedEmployees();
					if (!aSelected.length) {
						MessageBox.information(
							Assignment.t(
								oBundle,
								"assignNeedEmployees",
								"Bitte mindestens einen Mitarbeiter auswählen."
							)
						);
						return;
					}
					var that = this;
					this._oAsgModel.setProperty("/busy", true);
					var p = Promise.resolve();
					aSelected.forEach(function (oEmp) {
						p = p.then(function () {
							return that._refreshCurrent(oEmp.pernr);
						});
					});
					p.finally(function () {
						that._oAsgModel.setProperty("/busy", false);
					});
				},

				onRemoveSelected: function () {
					var aCtx = this._selectedEmployeeContexts();
					if (!aCtx.length) {
						return;
					}
					var aRemove = {};
					aCtx.forEach(function (oCtx) {
						var o = oCtx.getObject();
						if (o && o.pernr) {
							aRemove[o.pernr] = true;
						}
					});
					var aEmployees = (
						this._oAsgModel.getProperty("/employees") || []
					).filter(function (o) {
						return !aRemove[o.pernr];
					});
					this._oAsgModel.setProperty("/employees", aEmployees);
					var oTable = this.byId("asgEmployeeTable");
					if (oTable) {
						oTable.removeSelections(true);
					}
				},

				onAssignSelected: function () {
					var oBundle = this._bundle();
					var oModel = this._odata();
					var oData = this._oAsgModel.getData();
					var sRule = String(oData.ruleId || "")
						.trim()
						.toUpperCase();
					var aSelected = this._selectedEmployees();
					if (!aSelected.length) {
						aSelected = oData.employees || [];
					}
					if (!sRule) {
						MessageBox.error(
							Assignment.t(
								oBundle,
								"assignRequired",
								"Ziel-AZP ist Pflicht."
							)
						);
						return;
					}
					if (!aSelected.length) {
						MessageBox.error(
							Assignment.t(
								oBundle,
								"assignNeedEmployees",
								"Bitte mindestens einen Mitarbeiter hinzufügen."
							)
						);
						return;
					}

					this._oAsgModel.setProperty("/ruleId", sRule);
					this._oAsgModel.setProperty("/busy", true);
					this._oAsgModel.setProperty("/message", "");

					var that = this;
					var nOk = 0;
					var nFail = 0;

					var p = Promise.resolve();
					aSelected.forEach(function (oEmp) {
						p = p.then(function () {
							var oParams = {
								Pernr: oEmp.pernr,
								RuleId: sRule,
								ValidFrom: oData.validFrom || Assignment.todayIso(),
								ValidTo: oData.validTo || "9999-12-31"
							};
							if (
								oData.employmentPct !== "" &&
								oData.employmentPct != null
							) {
								oParams.EmploymentPct = Number(oData.employmentPct);
							}
							if (
								oData.weeklyHours !== "" &&
								oData.weeklyHours != null
							) {
								oParams.WeeklyHours = Number(oData.weeklyHours);
							}
							return Assignment.assignOne(oModel, oParams)
								.then(function (oRes) {
									var a =
										that._oAsgModel.getProperty("/employees") ||
										[];
									var i = Assignment.findEmployeeIndex(
										a,
										oEmp.pernr
									);
									if (i < 0) {
										return;
									}
									if (oRes && oRes.success === false) {
										nFail++;
										a[i].statusText =
											oRes.message ||
											Assignment.t(
												oBundle,
												"assignFailed",
												"Fehlgeschlagen"
											);
										a[i].statusState = "Error";
									} else {
										nOk++;
										a[i].currentRuleId = sRule;
										a[i].statusText =
											(oRes && oRes.message) ||
											Assignment.t(
												oBundle,
												"assignSuccessShort",
												"Zugeordnet"
											);
										a[i].statusState = "Success";
									}
									that._oAsgModel.setProperty(
										"/employees",
										a.slice()
									);
								})
								.catch(function (oErr) {
									nFail++;
									var a =
										that._oAsgModel.getProperty("/employees") ||
										[];
									var i = Assignment.findEmployeeIndex(
										a,
										oEmp.pernr
									);
									if (i >= 0) {
										a[i].statusText =
											(oErr && oErr.message) ||
											Assignment.t(
												oBundle,
												"assignFailed",
												"Fehlgeschlagen"
											);
										a[i].statusState = "Error";
										that._oAsgModel.setProperty(
											"/employees",
											a.slice()
										);
									}
								});
						});
					});

					p.finally(function () {
						that._oAsgModel.setProperty("/busy", false);
						var sMsg = Assignment.t(
							oBundle,
							"assignMassResult",
							"{0} erfolgreich, {1} fehlgeschlagen."
						)
							.replace("{0}", String(nOk))
							.replace("{1}", String(nFail));
						that._oAsgModel.setProperty("/message", sMsg);
						that._oAsgModel.setProperty(
							"/messageType",
							nFail ? "Warning" : "Success"
						);
						if (nOk && !nFail) {
							MessageToast.show(sMsg);
						}
					});
				}
			}
		);
	}
);
