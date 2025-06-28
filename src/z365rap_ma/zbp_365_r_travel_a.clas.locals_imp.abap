class lhc_Travel definition inheriting from cl_abap_behavior_handler.
  private section.

    constants:
      begin of travel_status,
        open     type c length 1 value 'O', "Open
        accepted type c length 1 value 'A', "Accepted
        reject   type c length 1 value 'X', "Rejected
      end of travel_status.

    methods get_instance_features for instance features
      importing keys request requested_features for Travel result result.

    methods get_instance_authorizations for instance authorization
      importing keys request requested_authorizations for Travel result result.

    methods get_global_authorizations for global authorization
      importing request requested_authorizations for Travel result result.

    methods precheck_create for precheck
      importing entities for create Travel.

    methods precheck_update for precheck
      importing entities for update Travel.

    methods acceptTravel for modify
      importing keys for action Travel~acceptTravel result result.

    methods deductDiscount for modify
      importing keys for action Travel~deductDiscount result result.

    methods reCalcTotalPrice for modify
      importing keys for action Travel~reCalcTotalPrice.

    methods rejectTravel for modify
      importing keys for action Travel~rejectTravel result result.

    methods Resume for modify
      importing keys for action Travel~Resume.

    methods calculateTotalPrice for determine on modify
      importing keys for Travel~calculateTotalPrice.

    methods setStatusToOpen for determine on modify
      importing keys for Travel~setStatusToOpen.

    methods setTravelNumber for determine on save
      importing keys for Travel~setTravelNumber.

    methods validateAgency for validate on save
      importing keys for Travel~validateAgency.

    methods validateBookingFee for validate on save
      importing keys for Travel~validateBookingFee.

    methods validateCurrency for validate on save
      importing keys for Travel~validateCurrency.

    methods validateCustomer for validate on save
      importing keys for Travel~validateCustomer.

    methods validateDates for validate on save
      importing keys for Travel~validateDates.

endclass.

class lhc_Travel implementation.

  method get_instance_features.
  endmethod.

  method get_instance_authorizations.
  endmethod.

  method get_global_authorizations.
  endmethod.

  method precheck_create.
  endmethod.

  method precheck_update.
  endmethod.

  method acceptTravel.

    "  EML - Entity Manipulation Language

    modify entities of Z365_r_TRAVEL_A in local mode
           entity Travel
           update
           fields ( OverallStatus )
           with value #( for key in keys ( %tky          = key-%tky
                                           OverallStatus = travel_status-accepted ) ).

    read entities of Z365_r_TRAVEL_A in local mode
         entity Travel
         all fields
         with corresponding #( keys )
         result data(travels).

    result = value #( for travel in travels ( %tky   = travel-%tky
                                              %param = travel ) ).

  endmethod.

  method deductDiscount.
  endmethod.

  method reCalcTotalPrice.
  endmethod.

  method rejectTravel.

    modify entities of Z365_r_TRAVEL_A in local mode
         entity Travel
         update
         fields ( OverallStatus )
         with value #( for key in keys ( %tky          = key-%tky
                                         OverallStatus = travel_status-reject ) ).

    read entities of Z365_r_TRAVEL_A in local mode
         entity Travel
         all fields
         with corresponding #( keys )
         result data(travels).

    result = value #( for travel in travels ( %tky   = travel-%tky
                                              %param = travel ) ).

  endmethod.

  method Resume.
  endmethod.

  method calculateTotalPrice.
  endmethod.

  method setStatusToOpen.

    read entities of Z365_r_TRAVEL_A in local mode
       entity Travel
       fields ( OverallStatus )
       with corresponding #( keys )
       result data(travels).

    delete travels where OverallStatus is not initial.

    check travels is not initial.

    modify entities of Z365_r_TRAVEL_A in local mode
         entity Travel
         update
         fields ( OverallStatus )
         with value #( for travel in travels ( %tky          = travel-%tky
                                               OverallStatus = travel_status-open ) ).

  endmethod.

  method setTravelNumber.

    read entities of Z365_r_TRAVEL_A in local mode
         entity Travel
         fields ( TravelID )
         with corresponding #( keys )
         result data(travels).

    delete travels where TravelID is not initial.

    check travels is not initial.

    select single from z365_travel_a
           fields max( travel_id )
           into @data(max_TravelId).

    modify entities of Z365_r_TRAVEL_A in local mode
         entity Travel
         update
         fields ( TravelID )
         with value #( for travel in travels index into i ( %tky    = travel-%tky
                                                           TravelID = max_TravelId + i ) ).

  endmethod.

  method validateAgency.
  endmethod.

  method validateBookingFee.
  endmethod.

  method validateCurrency.
  endmethod.

  method validateCustomer.

    data customers type sorted table of /dmo/customer with unique key client customer_id.

    read entities of Z365_r_TRAVEL_A in local mode
         entity Travel
         fields ( CustomerID )
         with corresponding #( keys )
         result data(travels).

    customers = corresponding #( travels discarding duplicates mapping customer_id = CustomerID except * ).
    delete customers where customer_id is initial.

    if customers is not initial.

      select from /dmo/customer as db
             inner join @customers as it on db~customer_id = it~customer_id
             fields db~customer_id
             into table @data(valid_customers).

    endif.

    loop at travels into data(travel).

      append value #( %tky        = travel-%tky
                      %state_area = 'VALIDATE_CUSTOMER' ) to reported-travel.

      if travel-CustomerID is initial.

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky = travel-%tky
                        %state_area = 'VALIDATE_CUSTOMER'
                        %msg = new /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_customer_id
                                                            severity = if_abap_behv_message=>severity-error )
                        %element-CustomerId = if_abap_behv=>mk-on ) to reported-travel.

      elseif not line_exists( valid_customers[ customer_id = travel-CustomerID ] ).

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky = travel-%tky
                        %state_area = 'VALIDATE_CUSTOMER'
                        %msg = new /dmo/cm_flight_messages( textid      = /dmo/cm_flight_messages=>customer_unkown
                                                            customer_id = travel-CustomerID
                                                            severity    = if_abap_behv_message=>severity-error )
                        %element-CustomerId = if_abap_behv=>mk-on ) to reported-travel.

      endif.


    endloop.

  endmethod.

  method validateDates.
  endmethod.

endclass.
