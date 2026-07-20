sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"azpworkschedulerule/test/integration/pages/WorkScheduleRuleList",
	"azpworkschedulerule/test/integration/pages/WorkScheduleRuleObjectPage"
], function (JourneyRunner, WorkScheduleRuleList, WorkScheduleRuleObjectPage) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('azpworkschedulerule') + '/test/flpSandbox.html#azpworkschedulerule-tile',
        pages: {
			onTheWorkScheduleRuleList: WorkScheduleRuleList,
			onTheWorkScheduleRuleObjectPage: WorkScheduleRuleObjectPage
        },
        async: true
    });

    return runner;
});

