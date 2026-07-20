@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AZP: Tagesplantext'
define view entity ZI_ZAZP_DailyWorkScheduleText
  as select from t550s
{
  key t550s.motpr as DwsGrouping,
  key t550s.tprog as Code,
  key t550s.spras as Language,
      t550s.ttext as Description
}
