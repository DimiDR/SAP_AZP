@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AZP: Mitarbeiterzuordnung IT0007'
define view entity ZI_ZAZP_EmployeeAssignment
  as select from pa0007
{
  key pa0007.pernr as Pernr,
  key pa0007.endda as ValidTo,
      pa0007.begda as ValidFrom,
      pa0007.schkz as RuleId,
      pa0007.empct as EmploymentPct,
      pa0007.zterf as TimeMgmtStatus,
      pa0007.wostd as WeeklyHours
}
