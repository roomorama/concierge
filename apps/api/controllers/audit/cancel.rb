require_relative "../cancel"

module API::Controllers::Audit

  # API::Controllers::Audit::Cancel
  #
  # Cancels reservation from Audit.
  class Cancel
    include API::Controllers::Cancel

    def cancel_reservation(params)
      Audit::Client.new.cancel(params)
    end

    def supplier_name
      Audit::Client::SUPPLIER_NAME
    end
  end
end
