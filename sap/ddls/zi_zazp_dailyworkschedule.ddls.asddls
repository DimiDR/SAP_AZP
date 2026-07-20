@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AZP: Tagesarbeitszeitplan'
define view entity ZI_ZAZP_DailyWorkSchedule
  as select from t550a
    inner join t508a on t508a.motpr = t550a.motpr
  association to parent ZI_ZAZP_WorkScheduleRule as _Rule
    on  $projection.EsGrouping        = _Rule.EsGrouping
    and $projection.HolidayCalendarId = _Rule.HolidayCalendarId
    and $projection.PsGrouping        = _Rule.PsGrouping
    and $projection.RuleId            = _Rule.RuleId
    and $projection.RuleValidTo       = _Rule.ValidTo
  association [0..1] to ZI_ZAZP_DailyWorkScheduleText as _Text
    on  $projection.DwsGrouping = _Text.DwsGrouping
    and $projection.Code        = _Text.Code
{
  key t508a.zeity as EsGrouping,
  key t508a.mofid as HolidayCalendarId,
  key t508a.mosid as PsGrouping,
  key t508a.schkz as RuleId,
  key t508a.endda as RuleValidTo,
  key t550a.tprog as Code,
  key t550a.varia as Variant,
  key t550a.endda as ValidTo,
      t550a.motpr as DwsGrouping,
      t550a.begda as ValidFrom,
      t550a.sollz as TargetHours,
      // Empty TIMS ('') and HR end-of-day 24:00:00 are illegal for OData Edm.TimeOfDay
      cast( case cast( t550a.sobeg as abap.char(6) )
              when '' then '000000'
              when '240000' then '235959'
              else cast( t550a.sobeg as abap.char(6) )
            end as abap.tims ) as WorkStart,
      cast( case cast( t550a.soend as abap.char(6) )
              when '' then '000000'
              when '240000' then '235959'
              else cast( t550a.soend as abap.char(6) )
            end as abap.tims ) as WorkEnd,
      cast( case cast( t550a.nobeg as abap.char(6) )
              when '' then '000000'
              when '240000' then '235959'
              else cast( t550a.nobeg as abap.char(6) )
            end as abap.tims ) as NormalStart,
      cast( case cast( t550a.noend as abap.char(6) )
              when '' then '000000'
              when '240000' then '235959'
              else cast( t550a.noend as abap.char(6) )
            end as abap.tims ) as NormalEnd,
      cast( case cast( t550a.btbeg as abap.char(6) )
              when '' then '000000'
              when '240000' then '235959'
              else cast( t550a.btbeg as abap.char(6) )
            end as abap.tims ) as TolBegFrom,
      cast( case cast( t550a.btend as abap.char(6) )
              when '' then '000000'
              when '240000' then '235959'
              else cast( t550a.btend as abap.char(6) )
            end as abap.tims ) as TolBegTo,
      cast( case cast( t550a.etbeg as abap.char(6) )
              when '' then '000000'
              when '240000' then '235959'
              else cast( t550a.etbeg as abap.char(6) )
            end as abap.tims ) as TolEndFrom,
      cast( case cast( t550a.etend as abap.char(6) )
              when '' then '000000'
              when '240000' then '235959'
              else cast( t550a.etend as abap.char(6) )
            end as abap.tims ) as TolEndTo,
      cast( case cast( t550a.k1beg as abap.char(6) )
              when '' then '000000'
              when '240000' then '235959'
              else cast( t550a.k1beg as abap.char(6) )
            end as abap.tims ) as CoreStart,
      cast( case cast( t550a.k1end as abap.char(6) )
              when '' then '000000'
              when '240000' then '235959'
              else cast( t550a.k1end as abap.char(6) )
            end as abap.tims ) as CoreEnd,
      t550a.pamod as BreakId,
      _Rule,
      _Text
}
