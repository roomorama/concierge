module Woori

  # +Woori::Client+
  #
  # This class is a convenience class for the smaller classes under +Woori+.
  #
  # For more information on how to interact with Woori, check the project Wiki in due course.
  class Client
    SUPPLIER_NAME = "Woori"
    MAXIMUM_STAY_LENGTH = 6 # days

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    private

    def database
      @database ||= Concierge::OptionalDatabaseAccess.new(ReservationRepository)
    end

    #Private method to be used when quoting price.
    def stay_too_long_error
      Result.error(:stay_too_long, { quote: "Maximum length of stay must be less than #{MAXIMUM_STAY_LENGTH} nights." })
    end

  end
end