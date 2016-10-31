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

    GENERIC_ERROR = "Could not quote price with remote supplier".freeze

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
        return status 500, error_response("No supplier record in database.") unless supplier
        return status 404, error_response("Property not found") unless property_exists?(params[:property_id])

        quotation_result = quote_price(params)

        if quotation_result.success?
          @quotation = quotation_result.value
          self.body = API::Views::Quote.render(exposures)
        else
          announce_error(quotation_result)
          error_message = { quote: quotation_result.error.data || GENERIC_ERROR }
          code = 503
          if Concierge::Errors::Quote::ERROR_CODES_WITH_SUCCESS_RESPONSE.include? quotation_result.error.code
            code = 200
          end
          status code, error_response(error_message)
        end
      else
        status 422, error_response(params.error_messages)
      end
    end

    private

    def error_response(errors)
      response = { status: "error" }.merge!(errors: errors)
      json_encode(response)
    end

    def announce_error(result)
      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   "quote",
        supplier:    supplier_name,
        code:        result.error.code,
        description: result.error.data,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end

    def property_exists?(id)
      ! PropertyRepository.identified_by(id).
          from_supplier(supplier).first.nil?
    end

    def supplier
      @supplier ||= SupplierRepository.named supplier_name
    end

    # Get the quote result from client implementations.
    #
    # The +params+ argument given is an instance of +API::Controllers::Params::Quote+.
    #
    # This method is only invoked in case validations were successful, meaning that partner
    # implementations need not to care about presence and format of expected parameters
    #
    # Should return a +Result+ wrapping a +Quotation+ object.
    # See the documentation of those classes for further information.
    #
    # If the quotation is not successful, return the +Result+ with error,
    # then the response status will be 503, with a generic quote error message.
    #
    def quote_price(params)
      raise NotImplementedError
    end

    # Should return a string.
    # This is used when reporting error and
    # searching for property
    def supplier_name
      raise NotImplementedError
    end

  end

end
