require_relative "../cancel"

module API::Controllers::THH

  # API::Controllers::THH::Cancel
  #
  # Cancels reservation from THH.
  class Cancel
    include API::Controllers::Cancel

    def cancel_reservation(params)
      credentials = Concierge::Credentials.for(supplier_name)
      THH::Client.new(credentials).cancel(params)
    end

    def supplier_name
      THH::Client::SUPPLIER_NAME
    end
  end
end
