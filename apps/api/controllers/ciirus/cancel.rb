require_relative "../cancel"

module API::Controllers::Ciirus

  # API::Controllers::Ciirus::Cancel
  #
  # Cancels reservation from Ciirus.
  class Cancel
    include API::Controllers::Cancel

    params API::Controllers::Params::Cancel

    def cancel_reservation(params)
      credentials = Concierge::Credentials.for(supplier_name)
      Ciirus::Client.new(credentials).cancel(params)
    end

    def supplier_name
      Ciirus::Client::SUPPLIER_NAME
    end
  end
end
