@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking - Interface Entity'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z365_I_BOOKING_A
  as projection on Z365_r_BOOKING_A
{
  key BookingUUID,
      TavelUUID,
      BookingID,
      BookingDate,
      CustomerID,
      AirlineID,
      ConnectionID,
      FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      FlightPrice,
      CurrencyCode,
      BookingStatus,
      LocalLastChangedAt,
      
      /* Associations */
      _BookingStatus,
      _BookingSupplement : redirected to composition child Z365_I_BKSUPPL_A,
      _Carrier,
      _Connection,
      _Customer,
      _Travel : redirected to parent Z365_I_TRAVEL_A
}
