@EndUserText.label : 'AZP Draft: Wochenmuster'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zazp_d_week {

  key client            : mandt not null;
  key esgrouping        : dzeity not null;
  key holidaycalendarid : hident not null;
  key psgrouping        : mosid not null;
  key ruleid            : schkn not null;
  key validto           : endda not null;
  key weeknumber        : wonum not null;
  dwsgrouping           : motpr;
  periodid              : dzmodn;
  monday                : tprog;
  tuesday               : tprog;
  wednesday             : tprog;
  thursday              : tprog;
  friday                : tprog;
  saturday              : tprog;
  sunday                : tprog;
  "%admin"              : include sych_bdl_draft_admin_inc;

}
