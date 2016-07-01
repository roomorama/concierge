require_relative "../cancel"

module API::Controllers::Waytostay

  # API::Controllers::Waytostay::Booking
  #
  # Performs create booking for properties from Waytostay.
  class Cancel
    include API::Controllers::Cancel

    def cancel_reservation(params)
      Waytostay::Client.new.cancel(params)
    end

    def supplier_name
      Waytostay::Client::SUPPLIER_NAME
    end
  end
end
