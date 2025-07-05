class lhc_BookingSupplement definition inheriting from cl_abap_behavior_handler.
  private section.

    methods get_instance_authorizations for instance authorization
      importing keys request requested_authorizations for BookingSupplement result result.

    methods get_global_authorizations for global authorization
      importing request requested_authorizations for BookingSupplement result result.

    methods calculateTotalPrice for determine on modify
      importing keys for BookingSupplement~calculateTotalPrice.

    methods setBookSupplNumber for determine on modify
      importing keys for BookingSupplement~setBookSupplNumber.

    methods validateCurrency for validate on save
      importing keys for BookingSupplement~validateCurrency.

    methods validatePrice for validate on save
      importing keys for BookingSupplement~validatePrice.

    methods validateSupplement for validate on save
      importing keys for BookingSupplement~validateSupplement.

endclass.

class lhc_BookingSupplement implementation.

  method get_instance_authorizations.
  endmethod.

  method get_global_authorizations.
  endmethod.

  method calculateTotalPrice.

    " Parent UUIDs
    read entities of Z365_r_TRAVEL_A in local mode
         entity BookingSupplement by \_Travel
         fields ( TravelUUID  )
         with corresponding #(  keys  )
         result data(travels).

    " Trigger Travel Internal Action
    modify entities of Z365_r_TRAVEL_A in local mode
      entity Travel
        execute reCalcTotalPrice
          from corresponding  #( travels ).

  endmethod.

  method setBookSupplNumber.
  endmethod.

  method validateCurrency.
  endmethod.

  method validatePrice.
  endmethod.

  method validateSupplement.
  endmethod.

endclass.
