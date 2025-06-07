@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supplements - Interface entity'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z365_I_BKSUPPL_A
  as projection on Z365_r_BKSUPPL_A
{
  key BookSupplUUIS,
      TravelUUID,
      BookingUUID,
      BookingSupplementID,
      SupplementID,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      Price,
      CurrencyCode,
      
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      LocalLastChangedAt,
      
      /* Associations */
      _Booking : redirected to parent Z365_I_BOOKING_A,
      _Product,
      _SupplementText,
      _Travel : redirected to Z365_I_TRAVEL_A
}
