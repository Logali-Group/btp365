@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supplements - Consumption entity'
@Metadata.ignorePropagatedAnnotations: true

@Metadata.allowExtensions: true
@Search.searchable: true

define view entity Z365_C_BKSUPPL_A
  as projection on Z365_r_BKSUPPL_A
{
  key BookSupplUUIS,
      TravelUUID,
      BookingUUID,

      @Search.defaultSearchElement: true
      BookingSupplementID,

      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'SupplementDescription' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Supplement_StdVH',
                                                    element: 'SupplementID'},
                                           additionalBinding: [{ localElement: 'Price',
                                                                 element: 'Price',
                                                                 usage: #RESULT },

                                                                 { localElement: 'CurrencyCode',
                                                                 element: 'CurrencyCode',
                                                                 usage: #RESULT }],

                                          useForValidation: true }]
      SupplementID,
      _SupplementText.Description as SupplementDescription : localized,


      @Semantics.amount.currencyCode: 'CurrencyCode'
      Price,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CurrencyStdVH',
                                                    element: 'Currency' },
                                          useForValidation: true }]
      CurrencyCode,

      LocalLastChangedAt,

      /* Associations */
      _Booking : redirected to parent Z365_C_BOOKING_A,
      _Product,
      _SupplementText,
      _Travel  : redirected to Z365_c_TRAVEL_A
}
