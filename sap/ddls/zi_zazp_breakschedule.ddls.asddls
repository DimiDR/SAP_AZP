@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AZP: Pausenplan'
define view entity ZI_ZAZP_BreakSchedule
  as select from t550p
    inner join t508a on t508a.motpr = t550p.motpr
  association to parent ZI_ZAZP_WorkScheduleRule as _Rule
    on  $projection.EsGrouping        = _Rule.EsGrouping
    and $projection.HolidayCalendarId = _Rule.HolidayCalendarId
    and $projection.PsGrouping        = _Rule.PsGrouping
    and $projection.RuleId            = _Rule.RuleId
    and $projection.RuleValidTo       = _Rule.ValidTo
{
  key t508a.zeity as EsGrouping,
  key t508a.mofid as HolidayCalendarId,
  key t508a.mosid as PsGrouping,
  key t508a.schkz as RuleId,
  key t508a.endda as RuleValidTo,
  key t550p.pamod as BreakId,
  key t550p.seqno as SeqNo,
      t550p.motpr as DwsGrouping,
      // Empty TIMS ('') and HR end-of-day 24:00:00 are illegal for OData Edm.TimeOfDay
      cast(
        case cast( t550p.pabeg as abap.char(6) )
          when '' then '000000'
          when '240000' then '235959'
          else cast( t550p.pabeg as abap.char(6) )
        end as abap.tims ) as StartTime,
      cast(
        case cast( t550p.paend as abap.char(6) )
          when '' then '000000'
          when '240000' then '235959'
          else cast( t550p.paend as abap.char(6) )
        end as abap.tims ) as EndTime,
      t550p.pdbez as PaidHours,
      t550p.pdunb as UnpaidHours,
      t550p.stdaz as AfterHours,
      _Rule
}
