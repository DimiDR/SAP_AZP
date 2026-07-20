@EndUserText.label: 'AZP: Simulations-Tag'
define abstract entity ZI_ZAZP_SimDay
{
  CalendarDay  : dats;
  WeekNumber   : wonum;
  Weekday      : abap.int4;
  DwsCode      : tprog;
  TargetHours  : sollz;
  IsHoliday    : abap_boolean;
  DayType      : abap.char(1);
}
