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
  #   end
  #
  # The only method this module expects to be implemented is a +quote_price+
  # method. The +params+ argument given to it is an instance of +API::Controllers::Params::Quote+.
  #
  # This method is only invoked in case validations were successful, meaning that partner
  # implementations need not to care about presence and format of expected parameters
  #
  # The +quote_price+ is expected to return a +Quotation+ object, always. See the documentation
  # of that class for further information.
  #
  # If the quotation is not successful, this method returns the errors declared in the returned
  # +Quotation+ object, and the return status is 503.
  module Quote

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
        @quotation = quote_price(params)

        if quotation.successful?
          self.body = API::Views::Quote.render(exposures)
        else
          status 503, invalid_request(quotation.errors)
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

    def rescue_with_generic_quotation(supplier_name, &block)
      wrapped_quotation = yield
      if wrapped_quotation.success?
        wrapped_quotation.result
      else
        announce_error(wrapped_quotation, supplier_name)
        Quotation.new(errors: { quote: "Could not quote price with remote supplier" })
      end
    end

    def announce_error(result, supplier_name)
      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   "quote",
        supplier:    supplier_name,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end

  end

end
