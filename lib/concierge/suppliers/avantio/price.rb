module Avantio

  # +Avantio::Price+
  #
  # This class is responsible for wrapping the logic related to making a price quotation
  # to Avantio, parsing the response, and building the +Quotation+ object with the data
  # returned from their API.
  #
  # Usage
  #
  #   result = Avantio::Price.new(credentials).quote(stay_params)
  #   if result.success?
  #     process_quotation(result.value)
  #   else
  #     handle_error(result.error)
  #   end
  #
  # The +quote+ method returns a +Result+ object that, when successful, encapsulates the
  # resulting +Quotation+ object.
  class Price
    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def quote(params)
      property = fetch_property(params[:property_id])
      return property_not_found unless property
      host = fetch_host(property.host_id)
      return host_not_found unless host

      # We should check availability at first, because
      # Avantio quote call returns valid price even for not available periods
      available = Avantio::Commands::IsAvailableFetcher.new(credentials).call(params)
      return available unless available.success?

      quotation = ::Quotation.new(
        property_id: params[:property_id],
        check_in:    params[:check_in].to_s,
        check_out:   params[:check_out].to_s,
        guests:      params[:guests],
        available:   available.value
      )

      if quotation.available
        quote = Avantio::Commands::QuoteFetcher.new(credentials).call(params)
        return quote unless quote.success?

        quotation.total    = quote.value.quote
        quotation.currency = quote.value.currency
      end

      quotation.host_fee_percentage = host.fee_percentage
      Result.new(quotation)
    end

    def property_not_found
      Result.error(:property_not_found)
    end

    def host_not_found
      Result.error(:host_not_found)
    end

    def fetch_host(id)
      HostRepository.find(id)
    end

    def fetch_property(id)
      PropertyRepository.identified_by(id).first
    end
  end
end