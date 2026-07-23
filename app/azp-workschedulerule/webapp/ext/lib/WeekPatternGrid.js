sap.ui.define(
	["sap/ui/model/json/JSONModel", "sap/m/MessageToast"],
	function (JSONModel, MessageToast) {
		"use strict";

		var DAY_KEYS = [
			"Monday",
			"Tuesday",
			"Wednesday",
			"Thursday",
			"Friday",
			"Saturday",
			"Sunday"
		];

		function _hoursMap(aDailies) {
			var m = {};
			(aDailies || []).forEach(function (o) {
				if (!o || !o.Code) {
					return;
				}
				m[o.Code] = Number(o.TargetHours) || 0;
			});
			return m;
		}

		function _buildRows(aWeeks, mHours, fAvgWeek) {
			return (aWeeks || [])
				.slice()
				.sort(function (a, b) {
					return String(a.WeekNumber || "").localeCompare(
						String(b.WeekNumber || ""),
						undefined,
						{ numeric: true }
					);
				})
				.map(function (oWeek) {
					var oRow = {
						WeekNumber: oWeek.WeekNumber,
						_contextPath: oWeek.__metadata && oWeek.__metadata.uri
					};
					var fSum = 0;
					DAY_KEYS.forEach(function (sDay) {
						var sCode = oWeek[sDay] || "";
						var fH = sCode ? mHours[sCode] : 0;
						if (fH === undefined) {
							fH = sCode === "FREI" || sCode === "OFF" ? 0 : null;
						}
						oRow[sDay] = sCode;
						oRow[sDay + "Hours"] =
							fH === null || fH === undefined ? "" : Number(fH).toFixed(2);
						if (typeof fH === "number") {
							fSum += fH;
						}
					});
					oRow.WeekSum = fSum.toFixed(2);
					oRow.AvgWeekHours = fAvgWeek != null ? Number(fAvgWeek).toFixed(2) : "";
					var fDiff =
						fAvgWeek != null ? Math.abs(fSum - Number(fAvgWeek)) : 0;
					oRow.SumState =
						fAvgWeek == null
							? "None"
							: fDiff <= 0.5
								? "Success"
								: "Warning";
					return oRow;
				});
		}

		function _readNav(oBindingContext, sNav) {
			if (!oBindingContext) {
				return Promise.resolve([]);
			}
			if (typeof oBindingContext.requestObject === "function") {
				return oBindingContext
					.requestObject(sNav)
					.then(function (v) {
						if (Array.isArray(v)) {
							return v;
						}
						if (v && Array.isArray(v.value)) {
							return v.value;
						}
						return [];
					})
					.catch(function () {
						return [];
					});
			}
			var oObj = oBindingContext.getObject() || {};
			var v = oObj[sNav];
			return Promise.resolve(Array.isArray(v) ? v : []);
		}

		function refresh(oView, oBindingContext) {
			if (!oView || !oBindingContext) {
				return Promise.resolve();
			}
			var oModel = oView.getModel("weekGrid");
			if (!oModel) {
				oModel = new JSONModel({
					rows: [],
					avgWeekHours: "",
					editable: false,
					busy: true
				});
				oView.setModel(oModel, "weekGrid");
			}
			oModel.setProperty("/busy", true);

			var oRoot = oBindingContext.getObject() || {};
			var fAvg = oRoot.AvgWeekHours;
			var bEdit =
				!!oView.getModel("ui") &&
				oView.getModel("ui").getProperty("/isEditable") === true;

			return Promise.all([
				_readNav(oBindingContext, "_Weeks"),
				_readNav(oBindingContext, "_DailySchedules")
			]).then(function (aRes) {
				var aWeeks = aRes[0];
				var aDailies = aRes[1];
				oModel.setData({
					rows: _buildRows(aWeeks, _hoursMap(aDailies), fAvg),
					avgWeekHours: fAvg != null ? Number(fAvg).toFixed(2) : "",
					editable: bEdit,
					busy: false,
					weekCount: aWeeks.length
				});
			});
		}

		/**
		 * Called from Object Page controller after section render / edit mode change.
		 */
		function attach(oExtensionAPI, oView) {
			if (!oExtensionAPI || !oView) {
				return;
			}
			var oCtx =
				typeof oExtensionAPI.getBindingContext === "function"
					? oExtensionAPI.getBindingContext()
					: null;
			if (!oCtx && oView.getBindingContext) {
				oCtx = oView.getBindingContext();
			}
			refresh(oView, oCtx);

			if (oView.getModel("ui") && !oView._azpWeekGridUiAttached) {
				oView._azpWeekGridUiAttached = true;
				oView.getModel("ui").attachPropertyChange(function (oEvent) {
					if (oEvent.getParameter("path") === "/isEditable") {
						refresh(
							oView,
							oView.getBindingContext && oView.getBindingContext()
						);
					}
				});
			}
		}

		function onDayChange(oEvent, oExtensionAPI) {
			var oInput = oEvent.getSource();
			var sDay = oInput.data("day");
			var sWeek = oInput.data("week");
			var sValue = (oEvent.getParameter("value") || "").toUpperCase().trim();
			var oCtx =
				typeof oExtensionAPI.getBindingContext === "function"
					? oExtensionAPI.getBindingContext()
					: null;
			if (!oCtx || !sDay || !sWeek) {
				return;
			}
			oInput.setValue(sValue);
			var oModel = oCtx.getModel();
			var oList = oModel.bindList(oCtx.getPath() + "/_Weeks");
			return oList.requestContexts(0, 200).then(function (aCtx) {
				var oMatch = (aCtx || []).find(function (c) {
					var o = c.getObject() || {};
					return String(o.WeekNumber) === String(sWeek);
				});
				if (!oMatch) {
					MessageToast.show("Wochenzeile nicht gefunden: " + sWeek);
					return;
				}
				oMatch.setProperty(sDay, sValue);
				var oView =
					typeof oExtensionAPI.getView === "function"
						? oExtensionAPI.getView()
						: null;
				return refresh(oView, oCtx);
			});
		}

		return {
			attach: attach,
			refresh: refresh,
			onDayChange: onDayChange,
			DAY_KEYS: DAY_KEYS
		};
	}
);
