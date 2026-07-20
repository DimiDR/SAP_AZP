@EndUserText.label : 'AZP Draft: Pausenplan'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zazp_d_break {

  key client            : mandt not null;
  key esgrouping        : dzeity not null;
  key holidaycalendarid : hident not null;
  key psgrouping        : mosid not null;
  key ruleid            : schkn not null;
  key rulevalidto       : endda not null;
  key breakid           : pamod not null;
  key seqno             : seqnp not null;
  dwsgrouping           : motpr;
  starttime             : pabeg;
  endtime               : paend;
  paidhours             : pdbez;
  unpaidhours           : pdunb;
  afterhours            : stdaz;
  "%admin"              : include sych_bdl_draft_admin_inc;

}
