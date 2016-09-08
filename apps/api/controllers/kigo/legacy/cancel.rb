require_relative "../cancel"

module API::Controllers::Kigo::Legacy

  # API::Controllers::Kigo::Legacy::Cancel
  #
  # Cancels reservation from Kigo Legacy.
  class Cancel
    include API::Controllers::Cancel

    def cancel_reservation(params)
      credentials = Concierge::Credentials.for(supplier_name)
      Kigo::Legacy.new(credentials).cancel(params)
    end

    def supplier_name
      Kigo::Legacy::SUPPLIER_NAME
    end
  end
end
