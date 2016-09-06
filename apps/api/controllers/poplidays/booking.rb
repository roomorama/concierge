require_relative "../booking"

module API::Controllers::Poplidays

  # +API::Controllers::Poplidays::Booking+
  #
  # Performs create booking for properties from Poplidays.
  class Booking
    include API::Controllers::Booking

    params API::Controllers::Params::Booking

    def create_booking(params)
      credentials = Concierge::Credentials.for(supplier_name)
      Poplidays::Client.new(credentials).book(params)
    end

    def supplier_name
      Poplidays::Client::SUPPLIER_NAME
    end
  end
end