module JTB
  # +JTB::ReferenceNumber+
  #
  # Represents identifier for JTB reservations.
  #
  # reservation_id is unique for JTB reservation, but cancel operation
  # required rate_plan_id as arg, so we need to store it as part of
  # roomorama reference_number
  # 
  # Usage when we need reference_number:
  #
  #  reference_number = ReferenceNumber.from_jtb_codes(reservation_id, rate_plan_id)
  #
  #  # To store it in Roomorama we should build reference_number
  #  roomorama_reference_number = reference_number.reference_number
  #
  # Usage when we need rate_plan_id or reservation_id:
  #
  #  # We know Roomorama reference_number
  #  reference_number = ReferenceNumber.from_roomorama_property_id(roomorama_reference_number)
  #  reservation_id = reference_number.reservation_id
  #  rate_plan_id  = reference_number.rate_plan_id
  class ReferenceNumber
    SEPARATOR = '|'

    attr_accessor :reservation_id, :rate_plan_id

    # Creates ReferenceNumber from Roomorama reference_number
    def self.from_roomorama_reference_number(reference_number)
      self.new.tap do |result|
        result.reservation_id, result.rate_plan_id = reference_number.split(SEPARATOR)
      end
    end

    # Creates ReferenceNumber from JTB data
    def self.from_jtb_ids(reservation_id, rate_plan_id)
      self.new.tap do |result|
        result.reservation_id = reservation_id
        result.rate_plan_id = rate_plan_id
      end
    end

    def reference_number
      [reservation_id, rate_plan_id].join(SEPARATOR)
    end
  end
end