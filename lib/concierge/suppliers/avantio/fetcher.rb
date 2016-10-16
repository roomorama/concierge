require 'zip'

module Avantio
  # +Avantio::Fetcher+
  #
  # Fetches and unzips all files data provided by Avantio.
  # To get access to the files only code_partner required.
  #
  # Usage:
  #
  # fetcher = Avantio::Fetcher.new(code_partner)
  # result = fetcher.fetch('accommodations')
  # result.value      # Nokogiri::XML::Document
  class Fetcher
    FILES_PATH = "http://feeds.avantio.com"

    # List of files supported by Avantio
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

    # Returns +Result+ wrapping +Nokogiri::XML::Document+
    def fetch(code)
      unless SUPPORTED_DATA.include?(code)
        return Result.error(:unknown_code, "Avantio supports only next files: #{SUPPORTED_DATA}")
      end
      zip = client.get(url(code))
      return zip unless zip.success?

      zip = zip.value.body
      Zip::InputStream.open(StringIO.new(zip)) do |io|
        # Archive should contain only one xml file
        # so read the first one. It is necessary to call this
        # method on a newly created InputStream before reading from
        # the first entry in the archive.
        io.get_next_entry
        io_to_xml(io)
      end
    end

    private

    def client
      @client = Concierge::HTTPClient.new(FILES_PATH)
    end

    def url(code)
      "/#{code}/#{code_partner}"
    end

    def io_to_xml(io)
      Result.new(Nokogiri::XML(io.read) { |config| config.strict })
    rescue Nokogiri::XML::SyntaxError => e
      Result.error(:xml_syntax_error)
    end
  end
end