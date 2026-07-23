@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AZP: Arbeitszeitplanregel'
define root view entity ZI_ZAZP_WorkScheduleRule
  as select from t508a
  composition [0..*] of ZI_ZAZP_WeekPattern as _Weeks
  composition [0..*] of ZI_ZAZP_DailyWorkSchedule as _DailySchedules
  composition [0..*] of ZI_ZAZP_BreakSchedule as _BreakSchedules
  association [0..*] to ZI_ZAZP_EmployeeAssignment as _Assignments
    on $projection.RuleId = _Assignments.RuleId
  association [0..1] to ZI_ZAZP_RuleText as _Text
    on  $projection.RuleId            = _Text.RuleId
    and $projection.EsGrouping        = _Text.EsGrouping
    and $projection.HolidayCalendarId = _Text.HolidayCalendarId
    and $projection.PsGrouping        = _Text.PsGrouping
    and _Text.Language                = $session.system_language
{
  key t508a.zeity as EsGrouping,
  key t508a.mofid as HolidayCalendarId,
  key t508a.mosid as PsGrouping,
  key t508a.schkz as RuleId,
  key t508a.endda as ValidTo,
      t508a.motpr as DwsGrouping,
      t508a.zmodn as PeriodId,
      @Semantics.businessDate.from: true
      t508a.begda as ValidFrom,
      t508a.tgstd as AvgDayHours,
      t508a.wostd as AvgWeekHours,
      t508a.m1std as AvgMonthHours,
      t508a.jrstd as AvgYearHours,
      t508a.wkwdy as WorkdaysPerWeek,
      t508a.bzpkt as ReferenceDate,
      t508a.offbz as OffsetDays,
      _Text.Description as Description,
      @EndUserText.label: 'Status'
      case
        when t508a.endda < $session.system_date then cast( 'Abgelaufen' as char12 )
        when t508a.begda > $session.system_date then cast( 'Geplant' as char12 )
        else cast( 'In SAP' as char12 )
      end as Status,
      @EndUserText.label: 'Status Criticality'
      case
        when t508a.endda < $session.system_date then cast( 1 as int4 )
        when t508a.begda > $session.system_date then cast( 2 as int4 )
        else cast( 5 as int4 )
      end as StatusCriticality,
      @Semantics.systemDateTime.lastChangedAt: true
      cast( '19700101000000.0000000' as abp_lastchange_tstmpl ) as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      cast( '19700101000000.0000000' as abp_locinst_lastchange_tstmpl ) as LocalLastChangedAt,
      _Weeks,
      _DailySchedules,
      _BreakSchedules,
      _Assignments,
      _Text
}
