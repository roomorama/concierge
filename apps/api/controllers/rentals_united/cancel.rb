require_relative "../cancel"

module API::Controllers::RentalsUnited
  # +API::Controllers::RentalsUnited::Cancel+
  #
  # Cancels reservation from RentalsUnited.
  class Cancel
    include API::Controllers::Cancel

    params API::Controllers::Params::Cancel

    def cancel_reservation(params)
      credentials = Concierge::Credentials.for(supplier_name)
      RentalsUnited::Client.new(credentials).cancel(params)
    end

    def supplier_name
      RentalsUnited::Client::SUPPLIER_NAME
    end
  end
end
