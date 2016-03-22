module API::Controllers

  # API::Controllers::InternalError
  #
  # This module is responsible for the handling of exceptions that might happen
  # while a request is being processed. In case an exception is raised, this
  # module catches it and returns a valid JSON response back to the caller
  # indicating the failure.
  #
  # It also reports the failure to Rollbar for later analysis.
  module InternalError

    def self.included(base)
      base.class_eval do
        include Concierge::JSON
        handle_exception StandardError => :generate_internal_error_message
      end
    end

    private

    def generate_internal_error_message(error)
      internal_error = {
        internal: "The request could not be processed due to an internal error. Please try again later."
      }
      response = { status: "error" }.merge!(errors: internal_error)

      Rollbar.error(error)

      status 500, json_encode(response)
    end
  end

end
