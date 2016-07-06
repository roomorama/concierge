module Kigo
  # +Kigo::Importer+
  #
  # This class wraps supplier API and provides data for building properties.
  #
  # Usage
  #
  #   importer = Kigo::Importer.new(credentials)
  #   importer.fetch_properties
  #
  #   => #<Result:0x007ff5fc624dd8 @result=[{"PROP_ID"=>111985, "PROP_PROVIDER"=>{...}}, ...]
  class Importer

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # retrieves the list of properties
    def fetch_properties
    end

    def fetch_data(id)
    end

  end
end


