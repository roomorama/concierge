module Web::Support
  module JSONEncode

    def json_encode(data)
      Yajl::Encoder.new.encode(data)
    end

  end
end
