@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supplements - Root entity'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity Z365_r_BKSUPPL_A
  as select from z365_bksuppl_a

  association        to parent Z365_r_BOOKING_A as _Booking        on $projection.BookingUUID = _Booking.BookingUUID
  association [1..1] to Z365_r_TRAVEL_A         as _Travel         on $projection.TravelUUID = _Travel.TravelUUID

  association [1..1] to /DMO/I_Supplement       as _Product        on $projection.SupplementID = _Product.SupplementID
  association [1..*] to /DMO/I_SupplementText   as _SupplementText on $projection.SupplementID = _SupplementText.SupplementID

{
  key booksuppl_uuid        as BookSupplUUIS,
      root_uuid             as TravelUUID,
      parent_uuid           as BookingUUID,


      booking_supplement_id as BookingSupplementID,
      supplement_id         as SupplementID,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      price                 as Price,
      currency_code         as CurrencyCode,

      //local ETag field
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      _Booking,
      _Travel,
      _Product,
      _SupplementText
}
