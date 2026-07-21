sap.ui.define(
	[
		"sap/ui/model/json/JSONModel",
		"sap/m/Dialog",
		"sap/m/Button",
		"sap/m/Label",
		"sap/m/Input",
		"sap/m/VBox",
		"sap/m/MessageBox",
		"sap/m/MessageToast"
	],
	function (
		JSONModel,
		Dialog,
		Button,
		Label,
		Input,
		VBox,
		MessageBox,
		MessageToast
	) {
		"use strict";

		var ACTION =
			"com.sap.gateway.srvd_a2x.zui_zazp_workschedulerule.v0001.simulateMonth";

		function _dayTypeText(sType) {
			switch (String(sType)) {
				case "0":
					return "Frei";
				case "1":
					return "Arbeit";
				case "2":
					return "Feiertag";
				default:
					return sType || "";
			}
		}

		function _normalizeDays(aRaw) {
			if (!Array.isArray(aRaw)) {
				return [];
			}
			return aRaw
				.filter(Boolean)
				.map(function (o) {
					var fHours = Number(
						o.TargetHours != null ? o.TargetHours : o.targetHours || 0
					);
					var vHoliday = o.IsHoliday != null ? o.IsHoliday : o.isHoliday;
					var sDayType = o.DayType != null ? o.DayType : o.dayType;
					return {
						CalendarDay: o.CalendarDay || o.calendarDay || "",
						WeekNumber: o.WeekNumber || o.weekNumber || "",
						Weekday: o.Weekday != null ? o.Weekday : o.weekday,
						DwsCode: o.DwsCode || o.dwsCode || "",
						TargetHours: fHours,
						IsHoliday: vHoliday === true || vHoliday === "true",
						DayType: sDayType,
						DayTypeText: _dayTypeText(sDayType)
					};
				});
		}

		function _summarize(aDays) {
			var fSum = aDays.reduce(function (acc, d) {
				return acc + (Number(d.TargetHours) || 0);
			}, 0);
			var iHolidays = aDays.filter(function (d) {
				return d.IsHoliday;
			}).length;
			return {
				dayCount: aDays.length,
				monthHours: fSum.toFixed(2),
				holidayCount: iHolidays
			};
		}

		function _resolveContexts(oExtensionAPI, oContext, aSelectedContexts) {
			if (aSelectedContexts && aSelectedContexts.length) {
				return aSelectedContexts;
			}
			if (oContext && typeof oContext.getObject === "function") {
				return [oContext];
			}
			if (
				oExtensionAPI &&
				typeof oExtensionAPI.getSelectedContexts === "function"
			) {
				var aSel = oExtensionAPI.getSelectedContexts();
				if (aSel && aSel.length) {
					return aSel;
				}
			}
			return [];
		}

		function _askYearMonth() {
			return new Promise(function (resolve, reject) {
				var oYear = new Input({
					value: String(new Date().getFullYear()),
					maxLength: 4,
					width: "100%"
				});
				var oMonth = new Input({
					value: ("0" + (new Date().getMonth() + 1)).slice(-2),
					maxLength: 2,
					width: "100%"
				});
				var oDialog = new Dialog({
					title: "Monatssimulation",
					contentWidth: "20rem",
					content: new VBox({
						items: [
							new Label({ text: "Jahr", labelFor: oYear }),
							oYear,
							new Label({
								text: "Monat (01–12)",
								labelFor: oMonth
							}).addStyleClass("sapUiSmallMarginTop"),
							oMonth
						]
					}).addStyleClass("sapUiSmallMargin"),
					beginButton: new Button({
						text: "Simulieren",
						type: "Emphasized",
						press: function () {
							var sYear = (oYear.getValue() || "").trim();
							var sMonth = (oMonth.getValue() || "").trim();
							if (!/^\d{4}$/.test(sYear)) {
								MessageBox.error("Jahr als YYYY eingeben.");
								return;
							}
							if (!/^(0?[1-9]|1[0-2])$/.test(sMonth)) {
								MessageBox.error("Monat als 01–12 eingeben.");
								return;
							}
							oDialog.close();
							resolve({
								year: sYear,
								month: ("0" + sMonth).slice(-2)
							});
						}
					}),
					endButton: new Button({
						text: "Abbrechen",
						press: function () {
							oDialog.close();
							reject(new Error("cancelled"));
						}
					}),
					afterClose: function () {
						oDialog.destroy();
					}
				});
				oDialog.open();
			});
		}

		/**
		 * Bound action returns Collection(ComplexType ZI_ZAZP_SimDay).
		 * FE invokeAction does not surface that reliably — call OData V4 directly.
		 */
		function _executeAction(oContext, oParams) {
			var oModel = oContext.getModel();
			var oActionContext = oModel.bindContext(ACTION + "(...)", oContext);

			oActionContext.setParameter("SimYear", oParams.year);
			oActionContext.setParameter("SimMonth", oParams.month);

			return oActionContext.execute().then(function () {
				var oBound = oActionContext.getBoundContext();
				if (!oBound) {
					return [];
				}
				// Collection of complex types → requestObject() yields the array
				if (typeof oBound.requestObject === "function") {
					return oBound.requestObject().then(function (v) {
						if (Array.isArray(v)) {
							return v;
						}
						if (v && Array.isArray(v.value)) {
							return v.value;
						}
						if (v && typeof v === "object") {
							return [v];
						}
						return [];
					});
				}
				var vObj = oBound.getObject();
				if (Array.isArray(vObj)) {
					return vObj;
				}
				if (vObj && Array.isArray(vObj.value)) {
					return vObj.value;
				}
				return vObj ? [vObj] : [];
			});
		}

		function _openDialog(oExtensionAPI, aDays) {
			var oSummary = _summarize(aDays);
			var oModel = new JSONModel({
				days: aDays,
				summary: oSummary,
				title:
					"Monatssimulation (" +
					oSummary.dayCount +
					" Tage · " +
					oSummary.monthHours +
					" h · " +
					oSummary.holidayCount +
					" Feiertage)"
			});

			var oController = {
				onCloseSimulateDialog: function () {
					if (oExtensionAPI._azpSimDialog) {
						oExtensionAPI._azpSimDialog.close();
					}
				}
			};

			var pDialog = oExtensionAPI._azpSimDialog
				? Promise.resolve(oExtensionAPI._azpSimDialog)
				: oExtensionAPI
						.loadFragment({
							id: "azpSimulateMonthDialog",
							name: "azpworkschedulerule.ext.fragment.SimulateMonthDialog",
							controller: oController
						})
						.then(function (oDialog) {
							oExtensionAPI._azpSimDialog = oDialog;
							return oDialog;
						});

			return pDialog.then(function (oDialog) {
				oDialog.setModel(oModel, "sim");
				oDialog.open();
			});
		}

		/**
		 * Custom FE action handler (`this` === ExtensionAPI).
		 */
		function onPress(oContext, aSelectedContexts) {
			var oExtensionAPI = this;

			if (!oExtensionAPI || typeof oExtensionAPI.loadFragment !== "function") {
				MessageBox.error(
					"ExtensionAPI fehlt. App hart neu laden (Ctrl+F5)."
				);
				return Promise.resolve();
			}

			var aContexts = _resolveContexts(
				oExtensionAPI,
				oContext,
				aSelectedContexts
			);
			if (!aContexts.length) {
				MessageBox.error("Bitte zuerst eine Arbeitszeitplanregel auswählen.");
				return Promise.resolve();
			}

			return _askYearMonth()
				.then(function (oParams) {
					MessageToast.show(
						"Simuliere " + oParams.month + "/" + oParams.year + "…"
					);
					return _executeAction(aContexts[0], oParams);
				})
				.then(function (aRaw) {
					var aDays = _normalizeDays(aRaw);
					if (!aDays.length) {
						MessageBox.information(
							"Keine Simulationstage vom Backend. Jahr/Monat und Regel prüfen."
						);
						return;
					}
					return _openDialog(oExtensionAPI, aDays);
				})
				.catch(function (oError) {
					if (oError && oError.message === "cancelled") {
						return;
					}
					// eslint-disable-next-line no-console
					console.error("AZP simulateMonth failed:", oError);
					var sMsg =
						(oError &&
							(oError.message ||
								(oError.error && oError.error.message))) ||
						"Monatssimulation fehlgeschlagen.";
					MessageBox.error(String(sMsg));
				});
		}

		return {
			onPress: onPress,
			ACTION: ACTION
		};
	}
);
