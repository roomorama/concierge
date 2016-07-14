# +Quotation+
#
# This class wraps the price obtained from a partner for a booking. Partner clients
# are expected to wrap their response in a +Quotation+ object.
#
# Attributes
#
#   +property_id+: a String used to identify the property with the partner. Not related to Roomorama.
#   +unit_id+:     a String used to identify the property's unit with the partner. Not related to Roomorama.
#   +check_in+:    the check-in date for the stay
#   +check_out+:   the check-out date for the stay
#   +guests+:      the number of guests
#   +available+:   whether or not the property is available for the given dates
#   +total+:       the quoted price for the booking
#   +gross_rate+:  the quoted price returned from supplier API which included host fee
#   +currency+:    the currency used for the quotation
#
# The quotation is only successful if the +errors+ attribute is empty.
class Quotation
  include Hanami::Entity
  include Hanami::Validations

  attribute :property_id, type: String
  attribute :unit_id,     type: String
  attribute :check_in,    type: String
  attribute :check_out,   type: String
  attribute :guests,      type: Integer
  attribute :available,   type: Boolean
  attribute :total,       type: Float
  attribute :gross_rate,  type: Float
  attribute :currency,    type: String

end
