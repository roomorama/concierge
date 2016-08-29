require_relative "../cancel"

module API::Controllers::Woori

  # +API::Controllers::Woori::Cancel+
  #
  # Cancels reservation from Woori.
  class Cancel
    include API::Controllers::Cancel

    def cancel_reservation(params)
      credentials = Concierge::Credentials.for(supplier_name)
      Woori::Client.new(credentials).cancel(params)
    end

    def supplier_name
      Woori::Client::SUPPLIER_NAME
    end
  end
end
