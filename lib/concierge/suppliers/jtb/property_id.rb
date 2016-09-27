module JTB
  # +JTB::PropertyId+
  #
  # Represents identifier for JTB properties.
  #
  # Only the combination of City Code and Hotel code is unique in identifying a
  # specific JTB hotel.
  #
  # Usage during sync:
  #
  #  # During sync JTB gives us property ids
  #  p_id = PropertyId.from_jtb_ids(city_code, hotel_code)
  #
  #  # To store it in Roomorama we should build property_id
  #  roomorama_property_id = p_id.property_id
  #
  # Usage when we need hotel_code or city_code:
  #
  #  # We know Roomorama property_id
  #  p_id = PropertyId.from_roomorama_property_id(roomorama_property_id)
  #  city_code = p_id.city_code
  #  hotel_code  = p_id.hotel_code
  class PropertyId
    PROPERTY_ID_SEPARATOR = '|'

    attr_accessor :city_code, :hotel_code

    # Creates PropertyId from Roomorama property id
    def self.from_roomorama_property_id(property_id)
      self.new.tap do |result|
        result.city_code, result.hotel_code= property_id.split(PROPERTY_ID_SEPARATOR)
      end
    end

    # Creates PropertyId from JTB property ids
    def self.from_jtb_ids(city_code, hotel_code)
      self.new.tap do |result|
        result.city_code = city_code
        result.hotel_code = hotel_code
      end
    end

    def property_id
      [city_code, hotel_code].join(PROPERTY_ID_SEPARATOR)
    end
  end
end