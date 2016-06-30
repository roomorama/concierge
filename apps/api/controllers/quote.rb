require_relative "./params/quote"
require_relative "internal_error"

module API::Controllers

  # API::Controllers::Quote
  #
  # This module includes the logic for quoting bookings from partner APIs.
  # Partner integrations are supposed to follow a certain protocol, detailed
  # below, so that parameter validation and error handling is automaticaly handled.
  #
  # Usage
  #
  #   class API::Controllers::Partner::Quote
  #     include API::Controllers::Quote
  #
  #     def quote_price(params)
  #       Partner::Client.new.quote(params)
  #     end
  #     def supplier_name
  #       "partner"
  #     end
  #   end
  #
  # The method this module expects to be implemented are:
  # 1. +quote_price+
  # 2. +supplier_name+
  #
  # See the respective method documentations below
  #
  module Quote

    ERROR_MESSAGE = "Could not quote price with remote supplier".freeze

    def self.included(base)
      base.class_eval do
        include API::Action
        include Concierge::JSON
        include API::Controllers::InternalError

        params API::Controllers::Params::Quote

        expose :quotation
      end
    end

    def call(params)
      if params.valid?
        quotation_result = quote_price(params)

        if quotation_result.success?
          @quotation = quotation_result.value
          self.body = API::Views::Quote.render(exposures)
        else
          announce_error(quotation_result)
          status 503, invalid_request( { quote: ERROR_MESSAGE } )
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
        operation:   "quote",
        supplier:    supplier_name,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end

    # Get the quote result from client implementations.
    #
    # The +params+ argument given is an instance of +API::Controllers::Params::Quote+.
    #
    # This method is only invoked in case validations were successful, meaning that partner
    # implementations need not to care about presence and format of expected parameters
    #
    # Should return a +Result+ wrapping a +Quotation+ object.
    #
    # If the quotation is not successful, return the +Result+ with error,
    # then the response status will be 503, with a generic quote error message.
    #
    def quote_price(params)
      raise NotImplementedError
    end

    # This is used when reporting errors from the supplier.
    # Should return a string
    def supplier_name
      raise NotImplementedError
    end

  end

end
