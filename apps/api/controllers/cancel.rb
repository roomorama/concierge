require_relative "./params/cancel"
require_relative "internal_error"

module API::Controllers

  # API::Controllers::Cancel
  #
  # This module includes the logic for cancelling reservations from partner APIs.
  # Partner integrations are supposed to follow a certain protocol, detailed
  # below, so that parameter validation and error handling is automaticaly handled.
  #
  # Usage
  #
  #   class API::Controllers::Partner::Cancel
  #     include API::Controllers::Cancel
  #
  #     def cancel_reservation(params)
  #       Partner::Client.new.cancel(params)
  #     end
  #
  #     def supplier_name
  #       Partner::Client::SUPPLIER_NAME
  #     end
  #   end
  #
  # Client implementations must have methods:
  #   - cancel_reservation(params)
  #   - supplier_name
  #
  # See documentations for them below
  #
  module Cancel

    GENERIC_ERROR = "Could not cancel with remote supplier"

    def self.included(base)
      base.class_eval do
        include API::Action
        include Concierge::JSON
        include API::Controllers::InternalError

        params API::Controllers::Params::Cancel

        expose :cancelled_reference_number
      end
    end

    def call(params)
      return status 422, unsuccessful_response(params.error_messages) unless params.valid?

      cancellation_result = cancel_reservation(params)

      if cancellation_result.success?
        @cancelled_reference_number = cancellation_result.value
        self.body = API::Views::Cancel.render(exposures)
      else
        announce_error(cancellation_result)
        error_message = cancellation_result.error.data || { cancellation: GENERIC_ERROR }
        status 503, unsuccessful_response(error_message)
      end
    end

    private

    def unsuccessful_response(errors)
      response = { status: "error" }.merge!(errors: errors)
      json_encode(response)
    end

    def announce_error(result)
      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   "cancellation",
        supplier:    supplier_name,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end

    # The +params+ argument is an instance of +API::Controllers::Params::Cancel+.
    #
    # This method is only invoked in case validations were successful, meaning that partner
    # implementations need not to care about presence and format of expected parameters
    #
    # The +cancel_reservation+ should return a +Result+ wrapping the cancelled_reference_number string.
    # If cancellation is not succesful for any reason, augment the errors on to Context,
    # and return the error message in Result.error.data in the form below:
    #
    #    Result.error(:network_error) # Generic error will be in the response.
    #    or
    #    Result.error(:not_found, {cancellation: "Unable to find reservation"})
    #
    # If Result.error is present, then 503 is the returned, with either the error.data hash
    # or a generic message.
    #
    # Read documentation of +Result+, +Context+ for further information.
    def cancel_reservation(params)
      raise NotImplementedError
    end

    # This is used when reporting errors from this supplier.
    # Should return a string
    #
    def supplier_name
      raise NotImplementedError
    end
  end

end
