module RentalsUnited
  # +RentalsUnited::Client+
  class Client
    SUPPLIER_NAME = "RentalsUnited"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Quote RentalsUnited properties prices
    # If an error happens in any step in the process of getting a response back
    # from RentalsUnited, a result object with error is returned

    # Arguments
    #
    #   * +quotation_params+ [Concierge::SafeAccessHash] stay parameters
    #
    # Stay parameters are defined by the set of attributes from
    # +API::Controllers::Params::MultiUnitQuote+ params object.
    #
    # +quotation_params+ object includes:
    #
    #   * +property_id+
    #   * +check_in+
    #   * +check_out+
    #   * +guests+
    #
    # Usage
    #
    #   comamnd = RentalsUnited::Client.new(credentials)
    #   result = command.quote(params)
    #
    #   if result.success?
    #     # ...
    #   end
    #
    # Returns a +Result+ wrapping a +Quotation+ when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def quote(quotation_params)
      property = find_property(quotation_params[:property_id])
      return Result.error(:property_not_found) unless property

      command = RentalsUnited::Commands::QuotationFetcher.new(
        credentials,
        quotation_params,
        property.data.get("currency")
      )
      command.call
    end

    private
    def find_property(property_id)
      PropertyRepository.identified_by(property_id).first
    end
  end
end
