@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AZP: Wochenmuster'
define view entity ZI_ZAZP_WeekPattern
  as select from t551a
    inner join t508a
      on  t508a.motpr = t551a.motpr
      and t508a.zmodn = t551a.zmodn
  association to parent ZI_ZAZP_WorkScheduleRule as _Rule
    on  $projection.EsGrouping        = _Rule.EsGrouping
    and $projection.HolidayCalendarId = _Rule.HolidayCalendarId
    and $projection.PsGrouping        = _Rule.PsGrouping
    and $projection.RuleId            = _Rule.RuleId
    and $projection.ValidTo           = _Rule.ValidTo
{
  key t508a.zeity as EsGrouping,
  key t508a.mofid as HolidayCalendarId,
  key t508a.mosid as PsGrouping,
  key t508a.schkz as RuleId,
  key t508a.endda as ValidTo,
  key t551a.wonum as WeekNumber,
      t551a.motpr as DwsGrouping,
      t551a.zmodn as PeriodId,
      t551a.tprg1 as Monday,
      t551a.tprg2 as Tuesday,
      t551a.tprg3 as Wednesday,
      t551a.tprg4 as Thursday,
      t551a.tprg5 as Friday,
      t551a.tprg6 as Saturday,
      t551a.tprg7 as Sunday,
      _Rule
}
