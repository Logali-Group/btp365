class lhc_Travel definition inheriting from cl_abap_behavior_handler.
  private section.


    types:
      ty_travel_create               type table for create Z365_r_TRAVEL_A\\Travel,
      ty_travel_update               type table for update Z365_r_TRAVEL_A\\Travel,
      ty_travel_delete               type table for delete Z365_r_TRAVEL_A\\Travel,
      ty_travel_failed               type table for failed early Z365_r_TRAVEL_A\\Travel,
      ty_travel_reported             type table for reported early Z365_r_TRAVEL_A\\Travel,

      ty_travel_action_accept_import type table for action import Z365_r_TRAVEL_A\\Travel~acceptTravel,
      ty_travel_action_accept_result type table for action result Z365_r_TRAVEL_A\\Travel~acceptTravel.

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

    methods precheck_auth
      importing
        entities_create type ty_travel_create optional
        entities_update type ty_travel_update optional
      changing
        failed          type ty_travel_failed
        reported        type ty_travel_reported.

endclass.

class lhc_Travel implementation.

  method get_instance_features.

    read entities of Z365_r_TRAVEL_A in local mode
         entity Travel
         fields ( OverallStatus )
         with corresponding #( keys )
         result data(travels).

    result = value #( for travel in travels ( %tky = travel-%tky
                                              %field-BookingFee = cond #( when travel-OverallStatus = travel_status-accepted
                                                                          then if_abap_behv=>fc-f-read_only
                                                                          else if_abap_behv=>fc-f-unrestricted )
                                              %action-acceptTravel = cond #( when travel-OverallStatus = travel_status-accepted
                                                                          then if_abap_behv=>fc-o-disabled
                                                                          else if_abap_behv=>fc-o-enabled )
                                              %action-rejectTravel = cond #( when travel-OverallStatus = travel_status-reject
                                                                          then if_abap_behv=>fc-o-disabled
                                                                          else if_abap_behv=>fc-o-enabled )
                                              %action-deductDiscount = cond #( when travel-OverallStatus = travel_status-accepted
                                                                          then if_abap_behv=>fc-o-disabled
                                                                          else if_abap_behv=>fc-o-enabled )
                                              %assoc-_Booking = cond #( when travel-OverallStatus = travel_status-reject
                                                                          then if_abap_behv=>fc-o-disabled
                                                                          else if_abap_behv=>fc-o-enabled )  ) ).


  endmethod.

  method get_instance_authorizations.

    data: update_requested type abap_bool,
          update_granted   type abap_bool,
          delete_requested type abap_bool,
          delete_granted   type abap_bool.

    read entities of Z365_r_TRAVEL_A in local mode
        entity Travel
        fields ( AgencyID )
        with corresponding #( keys )
        result data(travels).

    update_requested = cond #( when requested_authorizations-%update = if_abap_behv=>mk-on
                                 or requested_authorizations-%action-Edit = if_abap_behv=>mk-on
                               then abap_true
                               else abap_false ).

    delete_requested = cond #( when requested_authorizations-%delete = if_abap_behv=>mk-on
                               then abap_true
                               else abap_false ).

    data(lv_technical_name) = cl_abap_context_info=>get_user_technical_name(  ).

    loop at travels into data(travel).

      if travel-AgencyID is not initial.

        if update_requested eq abap_true.

          if lv_technical_name eq 'CB9980003263' and travel-AgencyID ne '70014'.
            update_granted = abap_true.
          else.
            update_granted = abap_false.
            append value #( %msg = new /dmo/cm_flight_messages( textid     = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                                                agency_id  = travel-AgencyID
                                                               severity    = if_abap_behv_message=>severity-error )
                           %global = if_abap_behv=>mk-on ) to reported-travel.
          endif.


        endif.

      endif.

      if delete_requested eq abap_true.

        if lv_technical_name eq 'CB9980003263' and travel-AgencyID ne '70014'. "WHAT EVER
          delete_granted = abap_true.
        else.
          delete_granted = abap_false.
          append value #( %msg = new /dmo/cm_flight_messages( textid     = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                                              agency_id  = travel-AgencyID
                                                             severity    = if_abap_behv_message=>severity-error )
                         %global = if_abap_behv=>mk-on ) to reported-travel.
        endif.

      endif.

      append value #( let upd_auth = cond #( when update_granted eq abap_true
                                             then if_abap_behv=>auth-allowed
                                             else if_abap_behv=>auth-unauthorized )
                          del_auth = cond #( when delete_granted eq abap_true
                                             then if_abap_behv=>auth-allowed
                                             else if_abap_behv=>auth-unauthorized )
                      in
                          %tky         = travel-%tky
                          %update      = upd_auth
                          %action-Edit = upd_auth
                          %delete      = del_auth ) to result.

    endloop.

  endmethod.

  method get_global_authorizations.

    "CB9980003263

    data(lv_technical_name) = cl_abap_context_info=>get_user_technical_name(  ).

    "lv_technical_name = 'DIFFERENT'.

    if requested_authorizations-%create eq if_abap_behv=>mk-on.

      if lv_technical_name eq 'CB9980003263'.
        result-%create = if_abap_behv=>auth-allowed.
      else.

        result-%create = if_abap_behv=>auth-unauthorized.

        append value #( %msg = new /dmo/cm_flight_messages( textid      = /dmo/cm_flight_messages=>not_authorized
                                                            severity    = if_abap_behv_message=>severity-error )
                        %global = if_abap_behv=>mk-on ) to reported-travel.

      endif.

    endif.

    if requested_authorizations-%update      eq if_abap_behv=>mk-on or
       requested_authorizations-%action-Edit eq if_abap_behv=>mk-on.


      if lv_technical_name eq 'CB9980003263'.
        result-%update      = if_abap_behv=>auth-allowed.
        result-%action-Edit = if_abap_behv=>auth-allowed.
      else.

        result-%update      = if_abap_behv=>auth-unauthorized.
        result-%action-Edit = if_abap_behv=>auth-unauthorized.

        append value #( %msg = new /dmo/cm_flight_messages( textid      = /dmo/cm_flight_messages=>not_authorized
                                                            severity    = if_abap_behv_message=>severity-error )
                        %global = if_abap_behv=>mk-on ) to reported-travel.

      endif.

    endif.

    if requested_authorizations-%delete eq if_abap_behv=>mk-on.

      if lv_technical_name eq 'CB9980003263'.
        result-%delete = if_abap_behv=>auth-allowed.
      else.

        result-%delete = if_abap_behv=>auth-unauthorized.

        append value #( %msg = new /dmo/cm_flight_messages( textid      = /dmo/cm_flight_messages=>not_authorized
                                                            severity    = if_abap_behv_message=>severity-error )
                        %global = if_abap_behv=>mk-on ) to reported-travel.

      endif.
    endif.


  endmethod.

  method precheck_create.

    me->precheck_auth( exporting entities_create = entities
                     changing  failed          = failed-travel
                               reported        = reported-travel ).

  endmethod.

  method precheck_update.

    me->precheck_auth( exporting entities_update = entities
                      changing  failed         = failed-travel
                                reported       = reported-travel ).

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

    data travels_for_update type table for update Z365_r_TRAVEL_A.

    data(keys_with_valid_discount) = keys.

    loop at keys_with_valid_discount assigning field-symbol(<key_valid_discount>)
         where %param-discount_percent is initial
            or %param-discount_percent > 100
            or %param-discount_percent <= 0.

      append value #( %tky = <key_valid_discount>-%tky ) to failed-travel.

      append value #( %tky                     = <key_valid_discount>-%tky
                      %msg                       = new /dmo/cm_flight_messages(
                                                             textid   = /dmo/cm_flight_messages=>discount_invalid
                                                             severity = if_abap_behv_message=>severity-error )
                      %element-BookingFee        = if_abap_behv=>mk-on
                      %op-%action-deductDiscount = if_abap_behv=>mk-on ) to reported-travel.

    endloop.

    check failed-travel is initial.

    read entities of Z365_r_TRAVEL_A in local mode
           entity Travel
           fields ( BookingFee )
           with corresponding #( keys_with_valid_discount )
           result data(travels).

    data percentage type decfloat16.

    loop at travels assigning field-symbol(<travel>).

      data(discount_percent) = keys_with_valid_discount[ key id %tky = <travel>-%tky ]-%param-discount_percent.
      percentage = discount_percent / 100.
      data(reduce_fee) = <travel>-BookingFee * ( 1 - percentage ).

      append value #( %tky       = <travel>-%tky
                      BookingFee = reduce_fee ) to travels_for_update.

    endloop.

    modify entities of Z365_r_TRAVEL_A in local mode
           entity Travel
           update
           fields ( BookingFee )
           with travels_for_update.

    read entities of Z365_r_TRAVEL_A in local mode
             entity Travel
             all fields
             with corresponding #( keys )
             result data(travels_with_discount).

    result = value #( for travel in travels_with_discount (  %tky   = travel-%tky
                                                             %param = travel ) ).

  endmethod.

  method reCalcTotalPrice.

    types: begin of ty_amount_per_currencycode,
             amount        type /dmo/total_price,
             currency_code type /dmo/currency_code,
           end of ty_amount_per_currencycode.

    data: amount_per_currencycode type standard table of ty_amount_per_currencycode.

    read entities of Z365_r_TRAVEL_A in local mode
         entity Travel
         fields ( BookingFee CurrencyCode )
         with corresponding #( keys )
         result data(travels).

    delete travels where CurrencyCode is initial.

    loop at travels assigning field-symbol(<travel>).

      amount_per_currencycode = value #( ( amount        = <travel>-BookingFee
                                           currency_code = <travel>-CurrencyCode ) ).

      " Read Bookings
      read entities of Z365_r_TRAVEL_A in local mode
        entity Travel by \_Booking
          fields ( FlightPrice CurrencyCode )
        with value #( ( %tky = <travel>-%tky ) )
        result data(bookings).

      loop at bookings into data(booking) where CurrencyCode is not initial.
        collect value ty_amount_per_currencycode( amount        = booking-FlightPrice
                                                  currency_code = booking-CurrencyCode ) into amount_per_currencycode.
      endloop.

      " Read Booking Supplements
      read entities of Z365_r_TRAVEL_A in local mode
           entity Booking by \_BookingSupplement
           fields ( Price CurrencyCode )
           with value #( for rba_booking in bookings ( %tky = rba_booking-%tky ) )
           result data(bookingsupplements).

      loop at bookingsupplements into data(bookingsupplement) where CurrencyCode is not initial.
        collect value ty_amount_per_currencycode( amount        = bookingsupplement-Price
                                                  currency_code = bookingsupplement-CurrencyCode ) into amount_per_currencycode.
      endloop.

      clear <travel>-TotalPrice.

      loop at amount_per_currencycode into data(single_amount_per_currencycode).

        " Currency Conversion
        if single_amount_per_currencycode-currency_code = <travel>-CurrencyCode.
          <travel>-TotalPrice += single_amount_per_currencycode-amount.
        else.
          /dmo/cl_flight_amdp=>convert_currency(
             exporting
               iv_amount                   =  single_amount_per_currencycode-amount
               iv_currency_code_source     =  single_amount_per_currencycode-currency_code
               iv_currency_code_target     =  <travel>-CurrencyCode
               iv_exchange_rate_date       =  cl_abap_context_info=>get_system_date( )
             importing
               ev_amount                   = data(total_booking_price_per_curr)
            ).
          <travel>-TotalPrice += total_booking_price_per_curr.
        endif.
      endloop.
    endloop.

    " write back the modified total_price of travels
    modify entities of Z365_r_TRAVEL_A in local mode
      entity travel
        update fields ( TotalPrice )
        with corresponding #( travels ).

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

    data entities_update type ty_travel_update.

    read entities of Z365_r_TRAVEL_A in local mode
         entity Travel
         fields ( AgencyID )
         with value #( for key in keys
                          %is_draft = if_abap_behv=>mk-on
                        ( %key = key-%key ) )
         result data(travels).

    " Set %control-AgencyID (if set) to true, so that the precheck_auth checks the permissions.
    entities_update = corresponding #( travels changing control ).

    if entities_update is not initial.
      me->precheck_auth( exporting entities_update = entities_update
                         changing failed           = failed-travel
                                   reported        = reported-travel ).
    endif.

  endmethod.

  method calculateTotalPrice.

    modify entities of Z365_r_TRAVEL_A in local mode
    entity Travel
    execute reCalcTotalPrice
    from corresponding #( keys ).

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

    data agencies type sorted table of /dmo/agency with unique key client agency_id.

    read entities of Z365_r_TRAVEL_A in local mode
         entity Travel
         fields ( AgencyID )
         with corresponding #( keys )
         result data(travels).

    agencies = corresponding #( travels discarding duplicates mapping agency_id = AgencyID except * ).
    delete agencies where agency_id is initial.

    if agencies is not initial.
      select from /dmo/agency as ddbb
             inner join @agencies as http_req on ddbb~agency_id eq http_req~agency_id
             fields ddbb~agency_id
             into table @data(valid_agencies).
    endif.

    loop at travels into data(travel).

      if travel-AgencyID is initial.

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_AGENCY'
                        %msg                = new /dmo/cm_flight_messages(
                                                               textid   = /dmo/cm_flight_messages=>enter_agency_id
                                                               severity = if_abap_behv_message=>severity-error )
                        %element-AgencyID = if_abap_behv=>mk-on ) to reported-travel.

      elseif not line_exists( valid_agencies[ agency_id = travel-AgencyID ] ).

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_AGENCY'
                        %msg                = new /dmo/cm_flight_messages(
                                                               textid      = /dmo/cm_flight_messages=>agency_unkown
                                                               agency_id   = travel-AgencyID
                                                               severity    = if_abap_behv_message=>severity-error )
                        %element-AgencyID = if_abap_behv=>mk-on ) to reported-travel.

      endif.


    endloop.

  endmethod.

  method validateBookingFee.
  endmethod.

  method validateCurrency.

    read entities of Z365_r_TRAVEL_A in local mode
        entity Travel
        fields ( CurrencyCode )
        with corresponding #( keys )
        result data(travels).

    data currencies type sorted table of I_Currency with unique key Currency.

    currencies = corresponding #( travels discarding duplicates mapping Currency = CurrencyCode except * ).
    delete currencies where Currency is initial.

    if currencies is not initial.

      select from I_Currency as ddbb
             inner join @currencies as http_req on ddbb~Currency = http_req~Currency
             fields ddbb~Currency
             into table @data(valid_currencies).

    endif.


    loop at travels into data(travel).

      append value #( %tky        = travel-%tky
                      %state_area = 'VALIDATE_CURRENCIES' ) to reported-travel.

      if travel-CurrencyCode is initial.

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky = travel-%tky
                        %state_area = 'VALIDATE_CURRENCIES'
                        %msg = new /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>currency_required
                                                            severity = if_abap_behv_message=>severity-error )
                        %element-CurrencyCode    = if_abap_behv=>mk-on ) to reported-travel.

      elseif travel-CurrencyCode is not initial and not line_exists( valid_currencies[ Currency = travel-CurrencyCode ] ).

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky = travel-%tky
                        %state_area = 'VALIDATE_CURRENCIES'
                        %msg = new /dmo/cm_flight_messages( textid        = /dmo/cm_flight_messages=>currency_not_existing
                                                            severity      = if_abap_behv_message=>severity-error
                                                            currency_code = travel-CurrencyCode )
                        %element-CurrencyCode    = if_abap_behv=>mk-on ) to reported-travel.

      endif.

    endloop.

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

    read entities of Z365_r_TRAVEL_A in local mode
            entity Travel
            fields (  BeginDate EndDate TravelID )
            with corresponding #( keys )
            result data(travels).

    loop at travels into data(travel).

      append value #(  %tky               = travel-%tky
                       %state_area        = 'VALIDATE_DATES' ) to reported-travel.

      if travel-BeginDate is initial.
        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg              = new /dmo/cm_flight_messages(
                                                                textid   = /dmo/cm_flight_messages=>enter_begin_date
                                                                severity = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) to reported-travel.
      endif.
      if travel-EndDate is initial.
        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg                = new /dmo/cm_flight_messages(
                                                                textid   = /dmo/cm_flight_messages=>enter_end_date
                                                                severity = if_abap_behv_message=>severity-error )
                        %element-EndDate   = if_abap_behv=>mk-on ) to reported-travel.
      endif.
      if travel-EndDate < travel-BeginDate and travel-BeginDate is not initial
                                           and travel-EndDate is not initial.
        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = new /dmo/cm_flight_messages(
                                                                textid     = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                                                begin_date = travel-BeginDate
                                                                end_date   = travel-EndDate
                                                                severity   = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on
                        %element-EndDate   = if_abap_behv=>mk-on ) to reported-travel.
      endif.
      if travel-BeginDate < cl_abap_context_info=>get_system_date( ) and travel-BeginDate is not initial.
        append value #( %tky               = travel-%tky ) to failed-travel.

        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg              = new /dmo/cm_flight_messages(
                                                                begin_date = travel-BeginDate
                                                                textid     = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                                                severity   = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) to reported-travel.
      endif.

    endloop.

  endmethod.

  method precheck_auth.

    "check 1 = 2.

    data:entities       type ty_travel_update,
         operation      type if_abap_behv=>t_char01,
         agencies       type sorted table of /dmo/agency with unique key agency_id,
         modify_granted type abap_bool.

    if entities_create is not initial.
      entities = corresponding #( entities_create mapping %cid_ref = %cid ).
      operation = if_abap_behv=>op-m-create.
    else.
      entities = entities_update.
      operation = if_abap_behv=>op-m-update.
    endif.

    delete entities where %control-AgencyID = if_abap_behv=>mk-off.

    agencies = corresponding #( entities discarding duplicates mapping agency_id = AgencyID except * ).

    check agencies is not initial.

    data(lv_technical_user) = cl_abap_context_info=>get_user_technical_name(  ).

    loop at entities into data(entity).

      modify_granted = abap_false.

      if lv_technical_user eq 'CB9980003263' and entity-AgencyID ne '70025'. "WHAT EVER
        modify_granted = abap_true.
      endif.

      if modify_granted = abap_false.
        append value #(  %cid      = cond #( when operation = if_abap_behv=>op-m-create
                                             then entity-%cid_ref )
                         %tky      = entity-%tky ) to failed.

        append value #(  %cid      = cond #( when operation = if_abap_behv=>op-m-create
                                             then entity-%cid_ref )
                         %tky      = entity-%tky
                         %msg      = new /dmo/cm_flight_messages(
                                                 textid    = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                                 agency_id = entity-AgencyID
                                                 severity  = if_abap_behv_message=>severity-error )
                         %element-AgencyID   = if_abap_behv=>mk-on  ) to reported.
      endif.
    endloop.

  endmethod.


endclass.
