require_relative "../booking"

module API::Controllers::Avantio

  # +API::Controllers::Avantio::Booking+
  #
  # Performs create booking for properties from Avantio.
  class Booking
    include API::Controllers::Booking

    params API::Controllers::Params::Booking

    def create_booking(params)
      credentials = Concierge::Credentials.for(supplier_name)
      Avantio::Client.new(credentials).book(params)
    end

    def supplier_name
      Avantio::Client::SUPPLIER_NAME
    end
  end
end
