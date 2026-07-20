@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AZP: Regeltext'
define view entity ZI_ZAZP_RuleText
  as select from t508s
{
  key t508s.schkz as RuleId,
  key t508s.zeity as EsGrouping,
  key t508s.mofid as HolidayCalendarId,
  key t508s.mosid as PsGrouping,
  key t508s.sprsl as Language,
      t508s.rtext as Description
}
