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
      host = find_host
      return host_not_found unless host

      property = find_property(quotation_params[:property_id])
      return property_not_found unless property

      command = RentalsUnited::Commands::PriceFetcher.new(
        credentials,
        quotation_params
      )
      result = command.call
      return result unless result.success?
      price = result.value

      mapper = RentalsUnited::Mappers::Quotation.new(
        price,
        property.data.get("currency"),
        quotation_params
      )
      Result.new(mapper.build_quotation)
    end

    private
    def find_host
      supplier = SupplierRepository.named(SUPPLIER_NAME)
      HostRepository.from_supplier(supplier).first
    end

    def find_property(property_id)
      PropertyRepository.identified_by(property_id).first
    end

    def host_not_found
      Result.error(:host_not_found)
    end

    def property_not_found
      Result.error(:property_not_found)
    end
  end
end
