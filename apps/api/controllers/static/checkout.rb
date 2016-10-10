require_relative "../internal_error"

module API::Controllers::Static

  # API::Controllers::Static::Checkout
  #
  # Artificial checkout endpoint to be provided by Roomorama integrations based
  # on Concierge. With the flow currently in place, the +checkout_instant+ event
  # required by Roomorama is actually not necessary for Concierge. Therefore,
  # instead of performing more API calls to suppliers, we just return a successful
  # response, allowing the process to continue.
  #
  # This is only possible because clients (Roomorama or otherwise) are expected to
  # quote prices before moving with the booking process.
  class Checkout
    include API::Action
    include Concierge::JSON
    include API::Controllers::InternalError

    def call(params)
      status 200, json_encode({ status: "ok" })
    end
  end
end
