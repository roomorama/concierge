module API::Support
  module JSONEncode

    # Encodes data to JSON.
    #
    # +data+: a Hash
    def json_encode(data)
      Yajl::Encoder.new.encode(data)
    end

  end
end
