@EndUserText.label: 'AZP: Tagesplan (Projektion)'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define view entity ZC_ZAZP_DailyWorkSchedule
  as projection on ZI_ZAZP_DailyWorkSchedule
{
  key EsGrouping,
  key HolidayCalendarId,
  key PsGrouping,
  key RuleId,
  key RuleValidTo,
  key Code,
  key Variant,
  key ValidTo,
      DwsGrouping,
      ValidFrom,
      TargetHours,
      WorkStart,
      WorkEnd,
      NormalStart,
      NormalEnd,
      TolBegFrom,
      TolBegTo,
      TolEndFrom,
      TolEndTo,
      CoreStart,
      CoreEnd,
      BreakId,
      _Rule : redirected to parent ZC_ZAZP_WorkScheduleRule
}
