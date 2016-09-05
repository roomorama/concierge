module Poplidays

  # +Poplidays::Price+
  #
  # This class is responsible for performing price quotations for properties coming
  # from Poplidays, parsing the response and building the +Quotation+ object according
  # with the data returned by their API.
  #
  # Usage
  #
  #   result = Poplidays::Price.new.quote(stay_params)
  #   if result.success?
  #     process_quotation(result.value)
  #   else
  #     handle_error(result.error)
  #   end
  #
  # The price quotation API call is open - it requires no authentication. Therefore
  # no parameters are required to build this class.
  #
  # The +quote+ method returns a +Result+ object that, when successful, encapsulates
  # the resulting +Quotation+ object. Possible errors at this stage are:
  #
  # * +unrecognised_response+:  happens when the request was successful, but the format
  #                             of the response is not compatible to this class' expectations.
  # * +invalid_property_error+: only properties that require no confirmation and have enabled prices
  #                             (accessed without Poplidays call center)
  #                             are supported at this moment.
  class Price

    CACHE_PREFIX = 'poplidays'
    MANDATORY_SERVICES_FRESHNESS = 12 * 60 * 60 # twelve hours

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Checks the price with Poplidays. Used booking/easy endpoint in "EVALUATION"
    # mode to get the price.
    #
    # Properties have also "mandatory services". These need to be accounted
    # for when calculating the subtotal. For that purpose, an API call to
    # the property details endpoint is made and that value is extracted.
    def quote(params)
      host = fetch_host
      return host_not_found unless host

      mandatory_services = retrieve_mandatory_services(params[:property_id])
      return mandatory_services unless mandatory_services.success?

      quote = retrieve_quote(params)
      return quote if unknown_errors?(quote)

      quotation = mapper.build(params, mandatory_services.value, quote)

      quotation.host_fee_percentage = host.fee_percentage
      Result.new(quotation)
    end

    private

    # Some unsuccessful (not 20X) http statuses of quote request
    # are valid business cases for us and should be handled:
    #   409 - stay specified in booking is no more available
    #   400 - bad arrival/departure date
    def unknown_errors?(quote)
      !quote.success? && ![:http_status_400, :http_status_409].include?(quote.error.code)
    end

    # Get the first Poplidays host, because there should only be one host
    def fetch_host
      supplier = SupplierRepository.named(Poplidays::Client::SUPPLIER_NAME)
      HostRepository.from_supplier(supplier).first
    end

    def host_not_found
      Result.error(:host_not_found)
    end

    def retrieve_quote(params)
      fetcher = Poplidays::Commands::QuoteFetcher.new(credentials)
      key = quote_cache_key(params)
      options = { serializer: Concierge::Cache::Serializers::JSON.new }
      with_cache(key, options) {
        fetcher.call(params)
      }
    end

    def retrieve_mandatory_services(property_id)
      key = ['property', property_id, 'mandatory_services'].join('.')
      options = { freshness: MANDATORY_SERVICES_FRESHNESS }
      with_cache(key, options) {
        fetcher = Poplidays::Commands::LodgingFetcher.new(credentials)
        result = fetcher.call(property_id)
        return result unless result.success?

        lodging = result.value
        if details_validator(lodging).valid?
          if lodging['mandatoryServicesPrice']
            Result.new(lodging['mandatoryServicesPrice'])
          else
            no_mandatory_services_data
            unrecognised_response
          end
        else
          invalid_property
          invalid_property_error
        end
      }
    end

    def details_validator(lodging)
      Poplidays::Validators::PropertyDetailsValidator.new(lodging)
    end

    def mapper
      @mapper ||= Poplidays::Mappers::Quote.new
    end

    def unrecognised_response
      Result.error(:unrecognised_response)
    end

    def no_mandatory_services_data
      message = "Expected to find the price for mandatory services under the " +
        "`mandatoryServicesPrice`, but none was found."

      mismatch(message, caller)
    end

    def invalid_property
      message = "Property shouldn't be on request only and should have enabled prices"
      mismatch(message, caller)
    end

    def invalid_property_error
      Result.error(:invalid_property_error)
    end

    def mismatch(message, backtrace)
      response_mismatch = Concierge::Context::ResponseMismatch.new(
        message:   message,
        backtrace: backtrace
      )

      Concierge.context.augment(response_mismatch)
    end

    def with_cache(key, options)
      cache.fetch(key, options) { yield }
    end

    def cache
      @cache ||= Concierge::Cache.new(namespace: CACHE_PREFIX)
    end

    def quote_cache_key(params)
      [params[:property_id], params[:check_in], params[:check_out]].join('.')
    end
  end

end
