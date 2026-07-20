@EndUserText.label : 'AZP Draft: Tagesplan'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zazp_d_daily {

  key client            : mandt not null;
  key esgrouping        : dzeity not null;
  key holidaycalendarid : hident not null;
  key psgrouping        : mosid not null;
  key ruleid            : schkn not null;
  key rulevalidto       : endda not null;
  key code              : tprog not null;
  key variant           : varia not null;
  key validto           : endda not null;
  dwsgrouping           : motpr;
  validfrom             : begda;
  targethours           : sollz;
  workstart             : sobeg;
  workend               : soend;
  normalstart           : nobeg;
  normalend             : noend;
  tolbegfrom            : btbeg;
  tolbegto              : btend;
  tolendfrom            : etbeg;
  tolendto              : etend;
  corestart             : k1beg;
  coreend               : k1end;
  breakid               : pamod;
  "%admin"              : include sych_bdl_draft_admin_inc;

}
