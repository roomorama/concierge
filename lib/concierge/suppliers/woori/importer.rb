module Woori
  # +Woori::Importer+
  #
  # This class provides an interface for the bulk import of Woori properties.
  # +Woori::Importer+ communicates and imports data from remote API.
  #
  # Usage
  #
  #   importer = Woori::Importer.new(credentials)
  #   importer.fetch_unit_rates("w_w0104006_R01")
  class Importer
    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Retrieves rates for unit by unit_id
    #
    # Arguments:
    #
    #   * +unit_id+ [String] unit id (room code hash in Woori API)
    #
    # Usage:
    #
    #   importer.fetch_unit_rates("w_w0104006_R01")
    #
    # Returns a +Result+ wrapping +Entities::UnitRates+ object
    # when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_unit_rates(unit_id)
      repository = Repositories::HTTP::UnitRates.new(credentials)
      repository.find_rates(unit_id)
    end
  end
end
