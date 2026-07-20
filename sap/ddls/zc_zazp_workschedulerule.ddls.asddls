@EndUserText.label: 'AZP: Arbeitszeitplanregel (Projektion)'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_ZAZP_WorkScheduleRule
  provider contract transactional_query
  as projection on ZI_ZAZP_WorkScheduleRule
{
  key EsGrouping,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_ZAZP_HolidayCalendar', element: 'HolidayCalendarId' } }]
  key HolidayCalendarId,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZC_ZAZP_WorkScheduleRule', element: 'PsGrouping' } }]
  key PsGrouping,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZC_ZAZP_WorkScheduleRule', element: 'RuleId' } }]
  key RuleId,
  key ValidTo,
      @Search.defaultSearchElement: true
      Description,
      DwsGrouping,
      PeriodId,
      ValidFrom,
      AvgDayHours,
      AvgWeekHours,
      AvgMonthHours,
      AvgYearHours,
      WorkdaysPerWeek,
      ReferenceDate,
      OffsetDays,
      LastChangedAt,
      LocalLastChangedAt,
      _Weeks           : redirected to composition child ZC_ZAZP_WeekPattern,
      _DailySchedules  : redirected to composition child ZC_ZAZP_DailyWorkSchedule,
      _BreakSchedules  : redirected to composition child ZC_ZAZP_BreakSchedule
}
