module SAW
  module Mappers
    class Country
      class << self
        def build(hash)
          Entities::Country.new(
            id: hash["@id"],
            name: hash["country_name"]
          )
        end
      end
    end
  end
end
