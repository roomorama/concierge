module Avantio
  # +Avantio::PropertyId+
  #
  # Represents identifier for Avantio properties.
  # The thing is that to work with particular Avantio property
  # their API methods requires three args: accommodation_code, user_code, login_ga.
  # But Roomorama stores property_id as one field.
  # This class allows to convert Avantio ids to Roomorama id and vice versa.
  #
  # Usage during metadata sync:
  #
  #  # During metadata sync Avantio gives us property ids
  #  p_id = PropertyId.from_avantio_ids(accommodation_code, user_code, login_ga)
  #
  #  # To store it in Roomorama we should build property_id
  #  roomorama_property_id = p_id.property_id
  #
  # Usage during Avantio API call:
  #
  #  # We know Roomorama property_id
  #  p_id = PropertyId.from_roomorama_property_id(roomorama_property_id)
  #  accommodation_code = p_id.accommodation_code
  #  user_code          = p_id.user_code
  #  login_ga           = p_id.login_ga
  class PropertyId
    PROPERTY_ID_SEPARATOR = '|'

    attr_accessor :accommodation_code, :user_code, :login_ga

    # Creates PropertyId from Roomorama property id
    def self.from_roomorama_property_id(property_id)
      self.new.tap do |result|
        result.accommodation_code, result.user_code, result.login_ga = property_id.split(PROPERTY_ID_SEPARATOR)
      end
    end

    # Creates PropertyId from Avantio property ids
    def self.from_avantio_ids(accommodation_code, user_code, login_ga)
      self.new.tap do |result|
        result.accommodation_code = accommodation_code
        result.user_code          = user_code
        result.login_ga           = login_ga
      end
    end

    def property_id
      [accommodation_code, user_code, login_ga].join(PROPERTY_ID_SEPARATOR)
    end
  end
end
