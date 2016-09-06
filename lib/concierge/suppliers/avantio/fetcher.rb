require 'zip'

module Avantio
  class Fetcher
    FILES_PATH = "http://feeds.avantio.com"
    SUPPORTED_DATA = %w(
      accommodations
      descriptions
      availabilities
      rates
      kinds
      geographicareas
      occupationalrules
      pricemodifiers
      services
    )

    attr_reader :code_partner

    def initialize(code_partner)
      @code_partner = code_partner
    end

    def fetch(code)
      return Result.error(:unknown_code) unless SUPPORTED_DATA.include?(code)
      zip = client.get(url(code))
      return unless zip.success?

      zip = zip.value.body
      Zip::InputStream.open(StringIO.new(zip)) do |io|
        # Archive should contain only one xml file
        # so read the first one. It is necessary to call this
        # method on a newly created InputStream before reading from
        # the first entry in the archive.
        io.get_next_entry
        return Result.new(Nokogiri::XML(io.read))
      end
    end

    private

    def client
      @client = Concierge::HTTPClient.new(FILES_PATH)
    end

    def url(code)
      "/#{code}/#{code_partner}"
    end
  end
end