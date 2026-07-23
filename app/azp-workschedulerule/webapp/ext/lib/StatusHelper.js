sap.ui.define([], function () {
	"use strict";

	/**
	 * Derive Fachbereich status from draft flags and optional Status field.
	 * Entwurf | Aktiv | In SAP
	 */
	function resolve(oData) {
		oData = oData || {};
		var bHasDraft =
			oData.HasDraftEntity === true || oData.HasDraftEntity === "true";
		var bIsActive =
			oData.IsActiveEntity === undefined ||
			oData.IsActiveEntity === null ||
			oData.IsActiveEntity === true ||
			oData.IsActiveEntity === "true";

		if (bHasDraft || bIsActive === false) {
			return {
				text: "Entwurf",
				state: "Warning",
				criticality: 2,
				step: 1
			};
		}

		var sStatus = String(oData.Status || "").trim();
		if (sStatus === "Entwurf") {
			return {
				text: "Entwurf",
				state: "Warning",
				criticality: 2,
				step: 1
			};
		}
		if (sStatus === "Aktiv") {
			return {
				text: "Aktiv",
				state: "Success",
				criticality: 3,
				step: 2
			};
		}
		// Persisted customizing in T508A ≈ already in SAP
		return {
			text: sStatus || "In SAP",
			state: "Information",
			criticality: 5,
			step: 3
		};
	}

	function fromContext(oContext) {
		if (!oContext) {
			return resolve({});
		}
		if (typeof oContext.getObject === "function") {
			return resolve(oContext.getObject() || {});
		}
		return resolve(oContext);
	}

	return {
		resolve: resolve,
		fromContext: fromContext
	};
});
