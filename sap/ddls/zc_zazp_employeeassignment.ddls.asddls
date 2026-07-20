@EndUserText.label: 'AZP: Mitarbeiterzuordnung (Projektion)'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define view entity ZC_ZAZP_EmployeeAssignment
  as select from ZI_ZAZP_EmployeeAssignment
{
  key Pernr,
  key ValidTo,
      ValidFrom,
      RuleId,
      EmploymentPct,
      TimeMgmtStatus,
      WeeklyHours
}
