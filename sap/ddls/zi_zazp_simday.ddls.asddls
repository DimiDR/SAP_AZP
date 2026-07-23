@EndUserText.label: 'AZP: Simulations-Tag / Transport / Zuordnung'
define abstract entity ZI_ZAZP_SimDay
{
  CalendarDay          : dats;
  WeekNumber           : wonum;
  Weekday              : abap.int4;
  DwsCode              : tprog;
  TargetHours          : sollz;
  IsHoliday            : abap_boolean;
  DayType              : abap.char(1);
  TransportRequest     : trkorr;
  TransportDescription : as4text;
  TransportOwner       : syuname;
  Pernr                : persno;
  RuleId               : schkn;
  ValidFrom            : begda;
  ValidTo              : endda;
  EmploymentPct        : empct;
  WeeklyHours          : wostd;
  Success              : abap_boolean;
  MessageText          : abap.char(255);
}
