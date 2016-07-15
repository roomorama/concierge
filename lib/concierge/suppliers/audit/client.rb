module Audit
  # +Audit::Client+
  #
  # This class is a convenience class for interacting with Audit.
  #
  # For more information on how to interact with Audit, check the project Wiki.
  class Client

    SUPPLIER_NAME = "Audit"

    attr_reader :credentials

    def initialize
      @credentials = Concierge::Credentials.for("audit")
    end

    # On success, return Result wrapping Quotation object
    def quote(params)
      client = Concierge::HTTPClient.new(credentials.host)
      result = client.get("/spec/fixtures/audit/quotation.#{params[:property_id]}.json")
      if result.success?
        json = JSON.parse(result.value.body)
        Result.new(Quotation.new(json['result']))
      else
        result
      end
    end

    # On success, return Result wrapping Reservation object
    def book(params)
      client = Concierge::HTTPClient.new(credentials.host)
      result = client.get("/spec/fixtures/audit/booking.#{params[:property_id]}.json")
      if result.success?
        json = JSON.parse(result.value.body)
        Result.new(Reservation.new(json['result']))
      else
        result
      end
    end

    # On success, return Result wrapping reservation_id String
    def cancel(params)
      client = Concierge::HTTPClient.new(credentials.host)
      result = client.get("/spec/fixtures/audit/cancel.#{params[:reservation_id]}.json")
      if result.success?
        json = JSON.parse(result.value.body)
        Result.new(json['result'])
      else
        result
      end
    end

    def announce_error(operation, result)
      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   operation,
        supplier:    SUPPLIER_NAME,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end

  end
end
