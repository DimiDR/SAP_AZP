@EndUserText.label : 'AZP Draft: Arbeitszeitplanregel'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zazp_d_rule {

  key client            : mandt not null;
  key esgrouping        : dzeity not null;
  key holidaycalendarid : hident not null;
  key psgrouping        : mosid not null;
  key ruleid            : schkn not null;
  key validto           : endda not null;
  description           : retext;
  dwsgrouping           : motpr;
  periodid              : dzmodn;
  validfrom             : begda;
  avgdayhours           : tgstd;
  avgweekhours          : wostd;
  avgmonthhours         : mostd;
  avgyearhours          : jrstd;
  workdaysperweek       : wkwdy;
  referencedate         : bzpkt;
  offsetdays            : offbz;
  lastchangedat         : abp_lastchange_tstmpl;
  locallastchangedat    : abp_locinst_lastchange_tstmpl;
  "%admin"              : include sych_bdl_draft_admin_inc;

}
