@EndUserText.label: 'AZP: Pausenplan (Projektion)'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define view entity ZC_ZAZP_BreakSchedule
  as projection on ZI_ZAZP_BreakSchedule
{
  key EsGrouping,
  key HolidayCalendarId,
  key PsGrouping,
  key RuleId,
  key RuleValidTo,
  key BreakId,
  key SeqNo,
      DwsGrouping,
      StartTime,
      EndTime,
      PaidHours,
      UnpaidHours,
      AfterHours,
      _Rule : redirected to parent ZC_ZAZP_WorkScheduleRule
}
