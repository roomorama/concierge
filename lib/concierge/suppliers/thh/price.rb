module THH

  # +THH::Price+
  #
  # This class is responsible for performing price quotations for properties coming
  # from THH, parsing the response and building the +Quotation+ object according
  # with the data returned by their API. THH available method doesn't have guests param,
  # Concierge checks it using property data from DB.
  #
  # Usage
  #
  #   result = THH::Price.new.quote(stay_params)
  #   if result.success?
  #     process_quotation(result.value)
  #   else
  #     handle_error(result.error)
  #   end
  #
  # The +quote+ method returns a +Result+ object that, when successful, encapsulates
  # the resulting +Quotation+ object. Possible errors at this stage are:
  #
  # * +max_guests_exceeded+
  class Price
    include Concierge::Errors::Quote

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def quote(params)
      max_guests = max_guests(params[:property_id])

      return max_guests_exceeded(max_guests) if params[:guests] > max_guests

      quote = retrieve_quote(params)
      return quote unless quote.success?

      Result.new(build_quotation(params, quote.value))
    end

    private

    def build_quotation(params, quote)
      quotation = Quotation.new(params)
      quotation.available = (quote['available'] == 'yes')

      if quotation.available
        quotation.total = rate_to_f(quote['price'])
        quotation.currency = THH::Commands::PropertiesFetcher::CURRENCY
      end

      quotation
    end

    def rate_to_f(rate)
      rate.gsub(/[,\s]/, '').to_f
    end

    def max_guests(property_id)
      property = find_property(property_id)
      property&.data&.get('max_guests').to_i
    end

    def find_property(identifier)
      PropertyRepository.identified_by(identifier).
        from_supplier(supplier).first
    end

    def supplier
      @supplier ||= SupplierRepository.named THH::Client::SUPPLIER_NAME
    end

    def retrieve_quote(params)
      fetcher = THH::Commands::QuoteFetcher.new(credentials)
      fetcher.call(params)
    end
  end
end
