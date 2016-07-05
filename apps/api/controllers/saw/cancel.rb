require_relative "../cancel"

module API::Controllers::SAW

  # +API::Controllers::SAW::Cancel+
  #
  # Cancels reservation from SAW.
  class Cancel
    include API::Controllers::Cancel

    def cancel_reservation(params)
      SAW::Client.new.cancel(params)
    end

    def supplier_name
      SAW::Client::SUPPLIER_NAME
    end
  end
end
