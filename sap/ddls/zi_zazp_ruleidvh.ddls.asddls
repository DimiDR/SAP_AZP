@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AZP: Value Help AZP-ID'
@Search.searchable: true
define view entity ZI_ZAZP_RuleIdVH
  as select distinct from t508a
{
      @Search.defaultSearchElement: true
      @EndUserText.label: 'AZP-ID'
  key t508a.schkz as RuleId
}
