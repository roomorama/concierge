module API::Controllers

  # +API::Controllers::ZendeskNotifyCancellation+
  #
  # This module implements the +cancel_reservation+ method expected to be present
  # on cancellation controllers that include the helper +API::Controllers::Cancel+
  # module.
  #
  # The +cancel_reservation+ expects a +supplier_name+ method to be implemented
  # (a requirement already enforced by +API::Controllers::Cancel+), and sends a request
  # to the +ZendeskNotify+ service to notify Customer Support about a supplier cancellation.
  #
  # To be used by suppliers which do not provide a cancellation API.
  module ZendeskNotifyCancellation

    def cancel_reservation(params)
      API::Support::ZendeskNotify.new.notify("cancellation", {
        supplier:    supplier_name,
        supplier_id: params[:reference_number],
        bridge_id:   params[:inquiry_id]
      })
    end

  end

end
