require_relative "./params/calendar"
require_relative "internal_error"

module API::Controllers

  # API::Controllers::Calendar
  #
  #
  # Usage
  #
  #   class API::Controllers::Supplier::Calendar
  #     include API::Controllers::Calendar
  #
  #     def pull_calendar(params)
  #       Supplier::Client.new.pull_calendar(params)
  #     end
  #   end
  #
  # The only method this module expects to be implemented is a +pull_calendar+
  # method. The +params+ argument given to it is an instance of +API::Controllers::Params::Calendar+.
  #
  # The +pull_calendar+ is expected to return a +Calendar+ object, always.  See the documentation
  # of that class for further information.
  #
  # If fetching the callendar cannot be performed at the time the request is received, this method
  # returns the errors declared in the returned +Calendar+ object, and the return status is 503.
  module Calendar

    def self.included(base)
      base.class_eval do
        include API::Action
        include Concierge::JSON
        include API::Controllers::InternalError

        params API::Controllers::Params::Calendar

        expose :calendar
      end
    end

    def call(params)
      if params.valid?
        @calendar = pull_calendar(params)

        if calendar.successful?
          self.body = API::Views::Calendar.render(exposures)
        else
          status 503, invalid_request(calendar.errors)
        end
      else
        status 422, invalid_request(params.error_messages)
      end
    end

    private

    def invalid_request(errors)
      response = { status: "error" }.merge!(errors: errors)
      json_encode(response)
    end
  end

end
