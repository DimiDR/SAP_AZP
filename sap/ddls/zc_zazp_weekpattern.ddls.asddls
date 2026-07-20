@EndUserText.label: 'AZP: Wochenmuster (Projektion)'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define view entity ZC_ZAZP_WeekPattern
  as projection on ZI_ZAZP_WeekPattern
{
  key EsGrouping,
  key HolidayCalendarId,
  key PsGrouping,
  key RuleId,
  key ValidTo,
  key WeekNumber,
      DwsGrouping,
      PeriodId,
      Monday,
      Tuesday,
      Wednesday,
      Thursday,
      Friday,
      Saturday,
      Sunday,
      _Rule : redirected to parent ZC_ZAZP_WorkScheduleRule
}
