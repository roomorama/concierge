module Web::Views
  module AcceptJSON
    def self.included(view)
      view.class_eval do
        format :json
      end

      def json(data)
        raw Yajl::Encoder.new.encode(data)
      end
    end
  end
end
