require_relative "../booking"

module API::Controllers::Audit

  # API::Controllers::Audit::Booking
  #
  # Performs create booking for properties from Audit.
  class Booking
    include API::Controllers::Booking

    def create_booking(params)
      Audit::Client.new.book(params)
    end

    def supplier_name
      Audit::Client::SUPPLIER_NAME
    end
  end
end

