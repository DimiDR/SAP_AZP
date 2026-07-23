@EndUserText.label: 'AZP: Employee Assignment Params'
define abstract entity ZA_ZAZP_MonthParams
{
  Pernr                : persno;
  RuleId               : schkn;
  ValidFrom            : begda;
  ValidTo              : endda;
  EmploymentPct        : empct;
  WeeklyHours          : wostd;
  KeyDate              : dats;
}
