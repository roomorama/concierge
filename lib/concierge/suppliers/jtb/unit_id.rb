module JTB
  # +JTB::UnitId+
  #
  # Represents identifier for JTB rooms.
  #
  # room_code is unique for JTB unit, but we cannot use it directly
  # because JTB API methods don't have such arg.
  # 
  # room_type_code is used to narrow search during quotation and booking requests
  # 
  # Usage during sync:
  #
  #  # During sync JTB gives us unit's codes
  #  u_id = UnitId.from_jtb_codes(room_type_code, room_code)
  #
  #  # To store it in Roomorama we should build unit_id
  #  roomorama_unit_id = u_id.unit_id
  #
  # Usage when we need room_code or room_type_code:
  #
  #  # We know Roomorama unit_id
  #  u_id = UnitId.from_roomorama_unit_id(roomorama_unit_id)
  #  room_type_code = u_id.room_type_code
  #  room_code  = u_id.room_code
  class UnitId
    SEPARATOR = '|'

    attr_accessor :room_type_code, :room_code

    # Creates UnitId from Roomorama unit id
    def self.from_roomorama_unit_id(unit_id)
      self.new.tap do |result|
        result.room_type_code, result.room_code= unit_id.split(SEPARATOR)
      end
    end

    # Creates UnitId from JTB data
    def self.from_jtb_codes(room_type_code, room_code)
      self.new.tap do |result|
        result.room_type_code = room_type_code
        result.room_code = room_code
      end
    end

    def unit_id
      [room_type_code, room_code].join(SEPARATOR)
    end
  end
end