module Ciirus

  # +Ciirus::Price+
  #
  # This class is responsible for wrapping the logic related to making a price quotation
  # to Ciirus, parsing the response, and building the +Quotation+ object with the data
  # returned from their API.
  #
  # Usage
  #
  #   result = Ciirus::Price.new(credentials).quote(stay_params)
  #   if result.success?
  #     process_quotation(result.value)
  #   else
  #     handle_error(result.error)
  #   end
  #
  # The +quote+ method returns a +Result+ object that, when successful, encapsulates the
  # resulting +Quotation+ object.
  # Actually the main logic of building the +Quotation+ object is in +QuoteFetcher+ class,
  # while +Price+ responsible for filling +host_fee_percentage+ field.
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

      quotation = Ciirus::Commands::QuoteFetcher.new(credentials).call(params)
      return quotation unless quotation.success?

      quotation.value.host_fee_percentage = host.fee_percentage
      quotation
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