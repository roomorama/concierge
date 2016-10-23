require_relative "../cancel"

module API::Controllers::JTB

  # API::Controllers::JTB::Cancel
  #
  # Cancels reservation from JTB.
  class Cancel
    include API::Controllers::Cancel

    params API::Controllers::Params::Cancel

    def cancel_reservation(params)
      credentials = Concierge::Credentials.for(supplier_name)
      JTB::Client.new(credentials).cancel(params)
    end

    def supplier_name
      JTB::Client::SUPPLIER_NAME
    end
  end
end
