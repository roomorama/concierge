require_relative "../cancel"

module API::Controllers::Waytostay

  # API::Controllers::Waytostay::Cancel
  #
  # Cancels reservation from Waytostay.
  class Cancel
    include API::Controllers::Cancel

    params API::Controllers::Params::Cancel

    def cancel_reservation(params)
      credentials = Concierge::Credentials.for(Ciirus::Client::SUPPLIER_NAME)
      Ciirus::Client.new(credentials).cancel(params)
    end

    def supplier_name
      Waytostay::Client::SUPPLIER_NAME
    end
  end
end
