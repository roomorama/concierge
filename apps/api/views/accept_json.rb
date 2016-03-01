module API::Views

  # +API::Views::AcceptJSON+
  #
  # This method enforces the response format to be JSON, since all API
  # responses are always in JSON format.
  #
  # It also adds a +json+ method to the views that allow them to return
  # a JSON payload directly from a +Hash+.
  #
  # Example
  #
  #   module API::Views::Partner
  #
  #     class Quote
  #       include API::Views::AcceptJSON # response format will be JSON automatically
  #
  #       def render
  #         json({ success: true })
  #       end
  #
  #     end
  #   end
  module AcceptJSON
    include API::Support::JSONEncode

    def self.included(view)
      view.class_eval do
        format :json
      end
    end

    def json(data)
      raw json_encode(data)
    end
  end
end
