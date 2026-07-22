sap.ui.define(
	[
		"sap/ui/model/json/JSONModel",
		"sap/m/MessageBox",
		"sap/m/MessageToast"
	],
	function (JSONModel, MessageBox, MessageToast) {
		"use strict";

		var NS =
			"com.sap.gateway.srvd_a2x.zui_zazp_workschedulerule.v0001";
		var ACTION_LIST = NS + ".listTransportRequests";
		var ACTION_CREATE = NS + ".createTransportRequest";
		var ACTION_SET = NS + ".setPreferredTransport";
		var ENTITY_SET = "/WorkScheduleRule";

		var _sSessionTrkorr = null;

		function _getModel(oExtensionAPI) {
			if (oExtensionAPI && typeof oExtensionAPI.getModel === "function") {
				return oExtensionAPI.getModel();
			}
			return null;
		}

		function _invokeStaticAction(oModel, sAction, oParams) {
			var sPath = ENTITY_SET + "/" + sAction + "(...)";
			var oActionContext = oModel.bindContext(sPath);
			Object.keys(oParams || {}).forEach(function (sKey) {
				oActionContext.setParameter(sKey, oParams[sKey]);
			});
			return oActionContext.execute().then(function () {
				var oBound = oActionContext.getBoundContext();
				if (!oBound) {
					return null;
				}
				if (typeof oBound.requestObject === "function") {
					return oBound.requestObject().then(function (v) {
						if (Array.isArray(v)) {
							return v;
						}
						if (v && Array.isArray(v.value)) {
							return v.value;
						}
						return v;
					});
				}
				var vObj = oBound.getObject();
				if (Array.isArray(vObj)) {
					return vObj;
				}
				if (vObj && Array.isArray(vObj.value)) {
					return vObj.value;
				}
				return vObj;
			});
		}

		function _normalizeRequests(vRaw) {
			var aRaw = Array.isArray(vRaw) ? vRaw : vRaw ? [vRaw] : [];
			return aRaw
				.map(function (o) {
					return {
						TransportRequest:
							o.TransportRequest || o.transportRequest || "",
						Description:
							o.TransportDescription ||
							o.transportDescription ||
							o.Description ||
							"",
						Owner: o.TransportOwner || o.transportOwner || o.Owner || ""
					};
				})
				.filter(function (o) {
					return !!o.TransportRequest;
				});
		}

		function _loadOpenRequests(oModel) {
			return _invokeStaticAction(oModel, ACTION_LIST, {}).then(function (v) {
				return _normalizeRequests(v);
			});
		}

		function _setPreferred(oModel, sTrkorr) {
			return _invokeStaticAction(oModel, ACTION_SET, {
				TransportRequest: sTrkorr
			}).then(function () {
				_sSessionTrkorr = sTrkorr;
				try {
					window.sessionStorage.setItem("azp.preferredTrkorr", sTrkorr);
				} catch (e) {
					/* ignore */
				}
				return sTrkorr;
			});
		}

		function _createAndPrefer(oModel, sDescription) {
			return _invokeStaticAction(oModel, ACTION_CREATE, {
				TransportDescription: sDescription || "AZP Customizing"
			}).then(function (v) {
				var a = _normalizeRequests(v);
				var sTrkorr = a.length ? a[0].TransportRequest : null;
				if (!sTrkorr && v && (v.TransportRequest || v.transportRequest)) {
					sTrkorr = v.TransportRequest || v.transportRequest;
				}
				if (!sTrkorr) {
					throw new Error("Kein Transportauftrag vom Backend erhalten.");
				}
				_sSessionTrkorr = sTrkorr;
				try {
					window.sessionStorage.setItem("azp.preferredTrkorr", sTrkorr);
				} catch (e) {
					/* ignore */
				}
				return sTrkorr;
			});
		}

		function _rememberedTrkorr() {
			if (_sSessionTrkorr) {
				return _sSessionTrkorr;
			}
			try {
				return window.sessionStorage.getItem("azp.preferredTrkorr") || null;
			} catch (e) {
				return null;
			}
		}

		function _destroyDialog(oExtensionAPI) {
			if (oExtensionAPI && oExtensionAPI._azpTrDialog) {
				oExtensionAPI._azpTrDialog.destroy();
				oExtensionAPI._azpTrDialog = null;
			}
		}

		/**
		 * Opens transport selection dialog. Resolves with chosen trkorr or rejects on cancel.
		 */
		function openDialog(oExtensionAPI) {
			var oModel = _getModel(oExtensionAPI);
			if (!oExtensionAPI || typeof oExtensionAPI.loadFragment !== "function") {
				return Promise.reject(new Error("ExtensionAPI fehlt."));
			}

			_destroyDialog(oExtensionAPI);

			var oTrModel = new JSONModel({
				busy: true,
				modeIndex: 0,
				selectedTrkorr: _rememberedTrkorr() || "",
				newDescription: "AZP Customizing",
				requests: []
			});

			return new Promise(function (resolve, reject) {
				var bSettled = false;
				function settleOk(sTrkorr) {
					if (bSettled) {
						return;
					}
					bSettled = true;
					_destroyDialog(oExtensionAPI);
					resolve(sTrkorr);
				}
				function settleCancel() {
					if (bSettled) {
						return;
					}
					bSettled = true;
					_destroyDialog(oExtensionAPI);
					reject(new Error("cancelled"));
				}

				var oController = {
					onModeChange: function () {
						/* binding handles visibility */
					},
					onConfirmTransport: function () {
						var oDlg = oExtensionAPI._azpTrDialog;
						var oModelTr = oDlg && oDlg.getModel("tr");
						if (!oModelTr) {
							MessageBox.error("Dialogmodell fehlt.");
							return;
						}
						var iMode = oModelTr.getProperty("/modeIndex");
						if (iMode === 1) {
							var sDesc = (oModelTr.getProperty("/newDescription") || "").trim();
							if (!sDesc) {
								MessageBox.error("Bitte eine Beschreibung eingeben.");
								return;
							}
							oModelTr.setProperty("/busy", true);
							_createAndPrefer(oModel, sDesc)
								.then(function (sTrkorr) {
									MessageToast.show(
										"Transportauftrag " + sTrkorr + " angelegt"
									);
									settleOk(sTrkorr);
								})
								.catch(function (oErr) {
									oModelTr.setProperty("/busy", false);
									MessageBox.error(
										(oErr && oErr.message) ||
											"Transportauftrag konnte nicht angelegt werden."
									);
								});
							return;
						}

						var sTrkorr = (oModelTr.getProperty("/selectedTrkorr") || "").trim();
						if (!sTrkorr) {
							MessageBox.error(
								"Bitte einen offenen Customizing-Auftrag wählen."
							);
							return;
						}
						oModelTr.setProperty("/busy", true);
						_setPreferred(oModel, sTrkorr)
							.then(function (sChosen) {
								MessageToast.show(
									"Transportauftrag " + sChosen + " gewählt"
								);
								settleOk(sChosen);
							})
							.catch(function (oErr) {
								oModelTr.setProperty("/busy", false);
								MessageBox.error(
									(oErr && oErr.message) ||
										"Transportauftrag konnte nicht gesetzt werden."
								);
							});
					},
					onCancelTransport: function () {
						settleCancel();
					}
				};

				oExtensionAPI
					.loadFragment({
						id: "azpTransportDialog",
						name: "azpworkschedulerule.ext.fragment.TransportDialog",
						controller: oController
					})
					.then(function (oDialog) {
						oExtensionAPI._azpTrDialog = oDialog;
						oDialog.setModel(oTrModel, "tr");
						oDialog.attachAfterClose(function () {
							if (!bSettled) {
								settleCancel();
							}
						});
						oDialog.open();
						return _loadOpenRequests(oModel)
							.then(function (aRequests) {
								oTrModel.setProperty("/requests", aRequests);
								oTrModel.setProperty("/busy", false);
								if (
									!oTrModel.getProperty("/selectedTrkorr") &&
									aRequests.length
								) {
									oTrModel.setProperty(
										"/selectedTrkorr",
										aRequests[0].TransportRequest
									);
								}
								if (!aRequests.length) {
									oTrModel.setProperty("/modeIndex", 1);
								}
							})
							.catch(function (oErr) {
								oTrModel.setProperty("/busy", false);
								oTrModel.setProperty("/modeIndex", 1);
								MessageToast.show(
									"Auftragsliste nicht ladbar – bitte neu anlegen."
								);
								// eslint-disable-next-line no-console
								console.error("AZP listTransportRequests failed:", oErr);
							});
					})
					.catch(function (oErr) {
						settleCancel();
						MessageBox.error(
							(oErr && oErr.message) || "Transport-Dialog fehlgeschlagen."
						);
					});
			});
		}

		/**
		 * Ensures a preferred transport is set (opens dialog). Used by onBeforeSave.
		 */
		function ensurePreferred(oExtensionAPI) {
			return openDialog(oExtensionAPI).catch(function (oErr) {
				if (oErr && oErr.message === "cancelled") {
					return Promise.reject(oErr);
				}
				MessageBox.error(
					(oErr && oErr.message) || "Transportauswahl fehlgeschlagen."
				);
				return Promise.reject(oErr);
			});
		}

		/**
		 * Custom FE action handler (`this` === ExtensionAPI).
		 */
		function onPress() {
			var oExtensionAPI = this;
			return ensurePreferred(oExtensionAPI).catch(function (oErr) {
				if (oErr && oErr.message === "cancelled") {
					return;
				}
			});
		}

		return {
			onPress: onPress,
			ensurePreferred: ensurePreferred,
			openDialog: openDialog,
			getRememberedTrkorr: _rememberedTrkorr,
			ACTION_LIST: ACTION_LIST,
			ACTION_CREATE: ACTION_CREATE,
			ACTION_SET: ACTION_SET
		};
	}
);
