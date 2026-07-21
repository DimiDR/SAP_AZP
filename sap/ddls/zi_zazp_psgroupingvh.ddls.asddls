@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AZP: Value Help PS-Gruppierung'
@Search.searchable: true
define view entity ZI_ZAZP_PsGroupingVH
  as select distinct from t508a
{
      @Search.defaultSearchElement: true
      @EndUserText.label: 'PS-Gruppierung'
  key t508a.mosid as PsGrouping
}
