require_relative "../cancel"

module API::Controllers::Kigo

  # API::Controllers::Kigo::Cancel
  #
  # Cancels reservation from Kigo.
  class Cancel
    include API::Controllers::Cancel

    def cancel_reservation(params)
      credentials = Concierge::Credentials.for(supplier_name)
      Kigo::Client.new(credentials).cancel(params)
    end

    def supplier_name
      Kigo::Client::SUPPLIER_NAME
    end
  end
end
