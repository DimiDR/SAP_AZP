sap.ui.define(
	[
		"sap/ui/core/mvc/ControllerExtension",
		"azpworkschedulerule/ext/lib/Transport",
		"azpworkschedulerule/ext/lib/WeekPatternGrid",
		"azpworkschedulerule/ext/lib/Validation"
	],
	function (ControllerExtension, Transport, WeekPatternGrid, Validation) {
		"use strict";

		return ControllerExtension.extend(
			"azpworkschedulerule.ext.controller.WorkScheduleRuleObjectPage",
			{
				override: {
					routing: {
						onAfterBinding: function (/* oBindingContext */) {
							this._attachAzpSections();
						}
					},
					editFlow: {
						/**
						 * Before Activate/Save: require customizing transport selection.
						 */
						onBeforeSave: function () {
							var oExtensionAPI =
								this.base && typeof this.base.getExtensionAPI === "function"
									? this.base.getExtensionAPI()
									: null;
							if (!oExtensionAPI) {
								return Promise.resolve();
							}
							return Transport.ensurePreferred(oExtensionAPI);
						}
					}
				},

				_attachAzpSections: function () {
					var oExtensionAPI =
						this.base && typeof this.base.getExtensionAPI === "function"
							? this.base.getExtensionAPI()
							: null;
					var oView =
						this.base && typeof this.base.getView === "function"
							? this.base.getView()
							: null;
					if (!oView) {
						return;
					}
					WeekPatternGrid.attach(oExtensionAPI, oView);
					Validation.attach(oExtensionAPI, oView);
				},

				onWeekDayChange: function (oEvent) {
					var oExtensionAPI =
						this.base && typeof this.base.getExtensionAPI === "function"
							? this.base.getExtensionAPI()
							: null;
					WeekPatternGrid.onDayChange(oEvent, oExtensionAPI);
				},

				onValidatePress: function () {
					var oExtensionAPI =
						this.base && typeof this.base.getExtensionAPI === "function"
							? this.base.getExtensionAPI()
							: null;
					return Validation.runValidate(oExtensionAPI);
				},

				onTransportPress: function () {
					var oExtensionAPI =
						this.base && typeof this.base.getExtensionAPI === "function"
							? this.base.getExtensionAPI()
							: null;
					return Validation.onTransport(oExtensionAPI);
				}
			}
		);
	}
);
