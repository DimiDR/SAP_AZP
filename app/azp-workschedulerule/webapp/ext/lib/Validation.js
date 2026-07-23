sap.ui.define(
	[
		"sap/ui/model/json/JSONModel",
		"sap/m/MessageBox",
		"sap/m/MessageToast",
		"azpworkschedulerule/ext/lib/StatusHelper",
		"azpworkschedulerule/ext/lib/Transport"
	],
	function (JSONModel, MessageBox, MessageToast, StatusHelper, Transport) {
		"use strict";

		var NS =
			"com.sap.gateway.srvd_a2x.zui_zazp_workschedulerule.v0001";
		// Draft determine action — must use FQN; short name "Prepare" → "Unknown bound action"
		var ACTION_PREPARE = NS + ".Prepare";

		var MSG_TEXTS = {
			"001": "Arbeitszeitplanregel (SCHKZ) ist leer",
			"002": "Arbeitszeitplanregel nicht gefunden",
			"003": "Gültig-ab muss kleiner/gleich Gültig-bis sein",
			"004": "Durchschnittswochenstunden außerhalb Bereich (20–48 h)",
			"005": "Periodenarbeitszeitplan nicht gefunden",
			"006": "Tagesplan existiert nicht",
			"007": "Wochensumme weicht vom Ø-Wochenwert ab (±0,5 h)",
			"010": "Tagesplan-Code ist leer",
			"011": "Tagesplan hat 0 Sollstunden (Frei-Tag)",
			"012": "Arbeitsbeginn muss vor Arbeitsende liegen",
			"013": "Kernzeitbeginn muss vor Kernzeitende liegen",
			"014": "Kernzeit muss innerhalb des Sollrahmens liegen",
			"015": "Kernzeit muss innerhalb der Normalzeit liegen",
			"016": "Normalzeit muss innerhalb des Sollrahmens liegen",
			"017": "Anfangstoleranz liegt außerhalb des Sollrahmens",
			"018": "Sollstunden nicht plausibel zu Rahmen/Pausen",
			"020": "Pausenplan ist leer",
			"021": "Pausenbeginn muss vor Pausenende liegen",
			"022": "Pause liegt außerhalb des Arbeitszeitrahmens",
			"023": "Pausenplan existiert nicht",
			"030": "Gültiger offener Customizing-Auftrag erforderlich",
			"050": "Kein offener Customizing-Auftrag verfügbar",
			"051": "Neue Regel-ID ist Pflicht",
			"052": "Kopieren/Transport fehlgeschlagen",
			"053": "Jahr und Monat sind Pflicht",
			"054": "Keine Simulationstage ermittelt",
			"055": "Speichern/Transport fehlgeschlagen",
			"056": "Löschen/Transport fehlgeschlagen"
		};

		function _ensureModel(oView) {
			var oModel = oView.getModel("valFlow");
			if (!oModel) {
				oModel = new JSONModel(_emptyState());
				oView.setModel(oModel, "valFlow");
			}
			return oModel;
		}

		function _emptyState() {
			return {
				busy: false,
				statusText: "–",
				statusState: "None",
				step1State: "None",
				step2State: "None",
				step3State: "None",
				step1Done: false,
				step2Done: false,
				step3Done: false,
				errorCount: 0,
				warningCount: 0,
				infoCount: 0,
				ok: false,
				messages: [],
				transport: "",
				hint: "Schritt 1: Validieren → Schritt 2: Transport → Schritt 3: Aktivieren/Speichern"
			};
		}

		function _friendlyText(oMsg) {
			var sCode = String(oMsg.code || oMsg.numericCode || "").replace(
				/\D/g,
				""
			);
			if (sCode.length >= 3) {
				sCode = sCode.slice(-3);
			}
			if (MSG_TEXTS[sCode]) {
				return MSG_TEXTS[sCode];
			}
			return (
				oMsg.message ||
				oMsg.fullText ||
				oMsg.text ||
				"Prüfungsmeldung ohne Text"
			);
		}

		function _severityState(s) {
			s = String(s || "").toLowerCase();
			if (s === "error" || s === "e" || s === "1") {
				return "Error";
			}
			if (s === "warning" || s === "w" || s === "2") {
				return "Warning";
			}
			return "Information";
		}

		function _collectMessages() {
			var aOut = [];
			try {
				var oMM = sap.ui.getCore().getMessageManager();
				var aAll = oMM.getMessageModel().getData() || [];
				aAll.forEach(function (o) {
					aOut.push({
						text: _friendlyText(o),
						state: _severityState(o.type || o.severity),
						target: o.target || o.additionalText || ""
					});
				});
			} catch (e) {
				/* ignore */
			}
			return aOut;
		}

		function refreshStatus(oView, oBindingContext) {
			var oModel = _ensureModel(oView);
			var oStatus = StatusHelper.fromContext(oBindingContext);
			var sTrkorr =
				typeof Transport.getRememberedTrkorr === "function"
					? Transport.getRememberedTrkorr()
					: "";
			oModel.setProperty("/statusText", oStatus.text);
			oModel.setProperty("/statusState", oStatus.state);
			oModel.setProperty("/transport", sTrkorr || "");
			oModel.setProperty("/step2Done", !!sTrkorr);
			oModel.setProperty("/step2State", sTrkorr ? "Success" : "None");
			oModel.setProperty(
				"/step3Done",
				oStatus.step >= 3 || oStatus.text === "In SAP" || oStatus.text === "Aktiv"
			);
			oModel.setProperty(
				"/step3State",
				oModel.getProperty("/step3Done") ? "Success" : "None"
			);
		}

		function _isDraftContext(oCtx) {
			if (!oCtx || typeof oCtx.getProperty !== "function") {
				return false;
			}
			try {
				var v = oCtx.getProperty("IsActiveEntity");
				return v === false || v === "false";
			} catch (e) {
				return false;
			}
		}

		/**
		 * Prepare only runs on draft. Prefer current draft context; else sibling draft path.
		 */
		function _resolvePrepareContext(oCtx) {
			if (!oCtx) {
				return Promise.resolve(null);
			}
			if (_isDraftContext(oCtx)) {
				return Promise.resolve(oCtx);
			}
			var sPath = oCtx.getPath && oCtx.getPath();
			if (!sPath || !/IsActiveEntity=true/i.test(sPath)) {
				return Promise.resolve(null);
			}
			var oModel = oCtx.getModel();
			var sDraftPath = sPath.replace(/IsActiveEntity=true/gi, "IsActiveEntity=false");
			var oDraftCtx = oModel.bindContext(sDraftPath).getBoundContext();
			if (!oDraftCtx || typeof oDraftCtx.requestObject !== "function") {
				return Promise.resolve(null);
			}
			return oDraftCtx.requestObject().then(
				function () {
					return oDraftCtx;
				},
				function () {
					return null;
				}
			);
		}

		/**
		 * Call RAP draft determine action Prepare via OData V4 (FQN), not FE short name.
		 */
		function _executePrepare(oContext) {
			var oModel = oContext.getModel();
			var oActionContext = oModel.bindContext(
				ACTION_PREPARE + "(...)",
				oContext
			);
			return oActionContext.execute();
		}

		function _applyValidateResult(oModel, oView, oCtx) {
			var aMsgs = _collectMessages();
			var iErr = aMsgs.filter(function (m) {
				return m.state === "Error";
			}).length;
			var iWarn = aMsgs.filter(function (m) {
				return m.state === "Warning";
			}).length;
			var iInfo = aMsgs.filter(function (m) {
				return m.state === "Information";
			}).length;
			var bOk = iErr === 0;

			oModel.setProperty("/busy", false);
			oModel.setProperty("/messages", aMsgs);
			oModel.setProperty("/errorCount", iErr);
			oModel.setProperty("/warningCount", iWarn);
			oModel.setProperty("/infoCount", iInfo);
			oModel.setProperty("/ok", bOk);
			oModel.setProperty("/step1Done", true);
			oModel.setProperty("/step1State", bOk ? "Success" : "Error");
			oModel.setProperty(
				"/hint",
				bOk
					? "Prüfung ohne Fehler. Als Nächstes Transport wählen und aktivieren."
					: "Bitte Fehler beheben, danach erneut validieren."
			);

			refreshStatus(oView, oCtx);

			if (bOk && aMsgs.length === 0) {
				MessageToast.show("Validierung ohne Beanstandungen");
			} else if (bOk) {
				MessageToast.show("Validierung OK – " + iWarn + " Hinweis(e)");
			} else {
				MessageBox.error(
					"Validierung gefunden: " +
						iErr +
						" Fehler, " +
						iWarn +
						" Warnung(en)."
				);
			}
		}

		function runValidate(oExtensionAPI) {
			var oView =
				oExtensionAPI &&
				typeof oExtensionAPI.getView === "function" &&
				oExtensionAPI.getView();
			if (!oView) {
				return Promise.resolve();
			}
			var oModel = _ensureModel(oView);
			oModel.setProperty("/busy", true);

			var oCtx =
				typeof oExtensionAPI.getBindingContext === "function"
					? oExtensionAPI.getBindingContext()
					: oView.getBindingContext();

			if (!oCtx) {
				oModel.setProperty("/busy", false);
				MessageBox.error("Kein Kontext für die Prüfung.");
				return Promise.resolve();
			}

			return _resolvePrepareContext(oCtx)
				.then(function (oPrepareCtx) {
					if (!oPrepareCtx) {
						oModel.setProperty("/busy", false);
						MessageBox.information(
							"Prüfung läuft über die Entwurfsaktion Prepare. Bitte zuerst Bearbeiten wählen."
						);
						return null;
					}
					return _executePrepare(oPrepareCtx).then(
						function () {
							return true;
						},
						function () {
							// Validations often reject with business messages — still collect them
							return true;
						}
					);
				})
				.then(function (bRan) {
					if (bRan) {
						_applyValidateResult(oModel, oView, oCtx);
					}
				})
				.catch(function (oErr) {
					oModel.setProperty("/busy", false);
					oModel.setProperty("/step1Done", true);
					oModel.setProperty("/step1State", "Error");
					oModel.setProperty("/ok", false);
					MessageBox.error(
						(oErr && oErr.message) ||
							"Validierung fehlgeschlagen. Bitte erneut versuchen."
					);
				});
		}

		function onTransport(oExtensionAPI) {
			return Transport.onPress.call(oExtensionAPI).then(function () {
				var oView =
					oExtensionAPI &&
					typeof oExtensionAPI.getView === "function" &&
					oExtensionAPI.getView();
				if (oView) {
					refreshStatus(
						oView,
						oExtensionAPI.getBindingContext &&
							oExtensionAPI.getBindingContext()
					);
				}
			});
		}

		function attach(oExtensionAPI, oView) {
			if (!oView) {
				return;
			}
			_ensureModel(oView);
			var oCtx =
				(oExtensionAPI &&
					oExtensionAPI.getBindingContext &&
					oExtensionAPI.getBindingContext()) ||
				oView.getBindingContext();
			refreshStatus(oView, oCtx);
		}

		/**
		 * Object Page header action (`this` === ExtensionAPI).
		 */
		function onHeaderValidatePress() {
			return runValidate(this);
		}

		/**
		 * List Report mass action (`this` === ExtensionAPI).
		 */
		function onMassValidatePress() {
			var oExtensionAPI = this;
			var aCtx = [];
			if (
				oExtensionAPI &&
				typeof oExtensionAPI.getSelectedContexts === "function"
			) {
				aCtx = oExtensionAPI.getSelectedContexts() || [];
			}
			if (!aCtx.length) {
				MessageToast.show("Bitte mindestens eine Regel markieren.");
				return Promise.resolve();
			}

			var iRan = 0;
			var iSkipped = 0;

			return aCtx
				.reduce(function (p, oCtx) {
					return p.then(function () {
						return _resolvePrepareContext(oCtx).then(function (
							oPrepareCtx
						) {
							if (!oPrepareCtx) {
								iSkipped += 1;
								return null;
							}
							return _executePrepare(oPrepareCtx).then(
								function () {
									iRan += 1;
								},
								function () {
									iRan += 1;
								}
							);
						});
					});
				}, Promise.resolve())
				.then(function () {
					if (iRan === 0) {
						MessageBox.information(
							"Keine Entwürfe unter den markierten Regeln. Bitte Regeln bearbeiten und erneut prüfen."
						);
						return;
					}
					var aMsgs = _collectMessages();
					var iErr = aMsgs.filter(function (m) {
						return m.state === "Error";
					}).length;
					var iWarn = aMsgs.filter(function (m) {
						return m.state === "Warning";
					}).length;
					var sSkip =
						iSkipped > 0
							? " (" + iSkipped + " ohne Entwurf übersprungen)"
							: "";
					if (iErr === 0) {
						MessageToast.show(
							"Prüfung abgeschlossen (" +
								iRan +
								" Regel(n)" +
								(iWarn ? ", " + iWarn + " Hinweis(e)" : "") +
								")" +
								sSkip
						);
					} else {
						MessageBox.error(
							"Massenprüfung: " +
								iErr +
								" Fehler, " +
								iWarn +
								" Warnung(en) bei " +
								iRan +
								" Regel(n)." +
								sSkip +
								" Details im Message-Popover."
						);
					}
				})
				.catch(function (oErr) {
					MessageBox.error(
						(oErr && oErr.message) ||
							"Massenvalidierung fehlgeschlagen."
					);
				});
		}

		return {
			attach: attach,
			runValidate: runValidate,
			onTransport: onTransport,
			refreshStatus: refreshStatus,
			onHeaderValidatePress: onHeaderValidatePress,
			onMassValidatePress: onMassValidatePress,
			MSG_TEXTS: MSG_TEXTS
		};
	}
);
