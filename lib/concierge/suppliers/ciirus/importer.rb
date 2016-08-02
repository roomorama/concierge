module Ciirus
  # +Ciirus::Importer+
  #
  # This class wraps supplier API and provides data for building properties.
  #
  # Usage
  #
  #   importer = Ciirus::Importer.new(credentials)
  #   importer.fetch_properties(host)
  #   importer.fetch_images
  #   importer.fetch_description
  class Importer

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Fetches all properties for given host from Ciirus API
    # Returns the Result wrapping the array of Ciirus::Entities::Property.
    def fetch_properties(host)
      fetcher = Commands::PropertiesFetcher.new(credentials)
      fetcher.call(mc_id: host.identifier)
    end

    # Returns the Result wrapping the array of images urls
    def fetch_images(property_id)
      fetcher = Commands::ImageListFetcher.new(credentials)
      fetcher.call(property_id)
    end

    # Returns the Result wrapping the array of Ciirus::Entities::PropertyRate
    def fetch_rates(property_id)
      fetcher = Commands::PropertyRatesFetcher.new(credentials)
      fetcher.call(property_id)
    end

    # Returns the Result wrapping the array of Ciirus::Entities::Reservation
    def fetch_reservations(property_id)
      fetcher = Commands::ReservationsFetcher.new(credentials)
      fetcher.call(property_id)
    end

    # Returns the Result wrapping the description string.
    #
    # Tries to fetch plain text description if possible,
    # sanitized html description otherwise.
    def fetch_description(property_id)
      plain_text_fetcher = Commands::DescriptionsPlainTextFetcher.new(credentials)
      result = plain_text_fetcher.call(property_id)
      if !result.success? || result.value.strip.empty?
        html_fetcher = Commands::DescriptionsHtmlFetcher.new(credentials)
        result = html_fetcher.call(property_id)
      end
      result
    end

    # Returns the Result wrapping the Ciirus::Entities::PropertyPermissions
    def fetch_permissions(property_id)
      fetcher = Commands::PropertyPermissionsFetcher.new(credentials)
      fetcher.call(property_id)
    end

    # Returns the Result wrapping the Ciirus::Entities::Extra
    def fetch_security_deposit(property_id)
      fetcher = Commands::SecurityDepositFetcher.new(credentials)
      fetcher.call(property_id)
    end
  end
end