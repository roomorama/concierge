require_relative "../booking"

module API::Controllers::Waytostay

  # API::Controllers::Waytostay::Booking
  #
  # Performs create booking for properties from Waytostay.
  class Booking
    include API::Controllers::Booking

    def create_booking(params)
      Waytostay::Client.new.book(params)
    end

    def supplier_name
      Waytostay::Client::SUPPLIER_NAME
    end
  end
end

