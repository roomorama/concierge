require_relative "../cancel"

module API::Controllers::Avantio

  # API::Controllers::Avantio::Cancel
  #
  # Cancels reservation from Avantio.
  class Cancel
    include API::Controllers::Cancel

    params API::Controllers::Params::Cancel

    def cancel_reservation(params)
      credentials = Concierge::Credentials.for(supplier_name)
      Avantio::Client.new(credentials).cancel(params)
    end

    def supplier_name
      Avantio::Client::SUPPLIER_NAME
    end
  end
end
