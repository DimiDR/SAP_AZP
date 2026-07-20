@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AZP: Feiertagskalender VH'
@Search.searchable: true
define view entity ZI_ZAZP_HolidayCalendar
  as select from thoci
{
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'Abbreviation' ]
  key thoci.ident as HolidayCalendarId,
      @EndUserText.label: 'Abbreviation'
      thoci.abbr  as Abbreviation,
      thoci.vjahr as ValidFromYear,
      thoci.bjahr as ValidToYear
}
