require_relative "../cancel"

module API::Controllers::AtLeisure

  # API::Controllers::AtLeisure::Cancel
  #
  # AtLeisure does not have a cancellation API. Therefore, when a booking is
  # cancelled, we notify Customer Support through Zendesk.
  class Cancel
    include API::Controllers::Cancel
    include API::Controllers::ZendeskNotifyCancellation

    def supplier_name
      AtLeisure::Client::SUPPLIER_NAME
    end
  end
end
