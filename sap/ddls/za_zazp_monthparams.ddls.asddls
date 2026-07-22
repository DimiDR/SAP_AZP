@EndUserText.label: 'AZP: Parameter Monatssimulation'
define abstract entity ZA_ZAZP_MonthParams
{
  SimYear              : abap.numc(4);
  SimMonth             : abap.numc(2);
  TransportRequest     : trkorr;
  TransportDescription : as4text;
}
