module SAW
  class ResponseParser
    def to_hash(result_body)
      Nori.new.parse(result_body)
    end
  end
end
