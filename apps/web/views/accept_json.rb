module Web::Views
  module AcceptJSON
    include Web::Support::JSONEncode

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
