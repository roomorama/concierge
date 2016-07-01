require_relative "./params/booking"
require_relative "internal_error"

module API::Controllers

  # API::Controllers::Booking
  #
  # This module includes the logic for creating bookings for partner properties on their side.
  # Partner integrations are supposed to follow a certain protocol, detailed
  # below, so that parameter validation and error handling is automaticaly handled.
  #
  # Usage
  #
  #   class API::Controllers::Partner::Booking
  #     include API::Controllers::Booking
  #
  #     def create_booking(params)
  #       Partner::Client.new.book(params)
  #     end
  #
  #     def supplier_name
  #       "partner"
  #     end
  #   end
  #
  # The method this module expects to be implemented are:
  # 1. +create_booking+
  # 2. +supplier_name+
  #
  module Booking

    GENERIC_ERROR = "Could not create booking with remote supplier"

    def self.included(base)
      base.class_eval do
        include API::Action
        include Concierge::JSON
        include API::Controllers::InternalError

        params API::Controllers::Params::Booking

        expose :reservation
      end
    end

    def call(params)
      if params.valid?
        reservation_result = create_booking(params)

        if reservation_result.success?
          @reservation = reservation_result.value
          self.body = API::Views::Booking.render(exposures)
        else
          announce_error(reservation_result)
          error_message = reservation_result.error.data || { booking: GENERIC_ERROR }
          status 503, invalid_request(error_message)
        end
      else
        status 422, invalid_request(params.error_messages)
      end
    end

    private

    def invalid_request(errors)
      response = { status: "error" }.merge!(errors: errors)
      json_encode(response)
    end

    def announce_error(result)
      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   "booking",
        supplier:    supplier_name,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end

    # Create booking with client
    #
    # The +params+ argument given to it is an instance of +API::Controllers::Params::Booking+.
    #
    # This method is only invoked in case validations were successful, meaning that partner
    # implementations need not to care about presence and format of expected parameters
    #
    # Should return a +Result+ wrapping a +Reservation+ object
    # See the documentation of those classes for further information.
    #
    # If the reservation is not successful, return the +Result+ with error,
    # then the response status will be 503, with a generic quote error message.
    #
    def create_booking(params)
      raise NotImplementedError
    end

    # This is used when reporting errors from the supplier.
    # Should return a string
    def supplier_name
      raise NotImplementedError
    end
  end

end
