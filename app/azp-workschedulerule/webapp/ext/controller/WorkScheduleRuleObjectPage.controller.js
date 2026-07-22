sap.ui.define(
	[
		"sap/ui/core/mvc/ControllerExtension",
		"azpworkschedulerule/ext/lib/Transport"
	],
	function (ControllerExtension, Transport) {
		"use strict";

		return ControllerExtension.extend(
			"azpworkschedulerule.ext.controller.WorkScheduleRuleObjectPage",
			{
				override: {
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
				}
			}
		);
	}
);
