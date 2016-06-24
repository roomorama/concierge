module SAW
  module Mappers
    class Country
      class << self
        def build(hash)
          Entities::Country.new(
            id: hash.get("@id"),
            name: hash.get("country_name")
          )
        end
      end
    end
  end
end
