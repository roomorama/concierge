require_relative "../cancel"
require_relative "../zendesk_notify_cancellation"

module API::Controllers::Poplidays

  # API::Controllers::Poplidays::Cancel
  #
  # Poplidays does not have a cancellation API. Therefore, when a booking is
  # cancelled, we notify Customer Support through Zendesk.
  class Cancel
    include API::Controllers::Cancel
    include API::Controllers::ZendeskNotifyCancellation

    def supplier_name
      Poplidays::Client::SUPPLIER_NAME
    end
  end
end
