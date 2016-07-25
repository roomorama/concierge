# +Quotation+
#
# This class wraps the price obtained from a partner for a booking. Partner clients
# are expected to wrap their response in a +Quotation+ object.
#
# Attributes
#
#   +property_id+:         a String used to identify the property with the partner. Not related to Roomorama.
#   +unit_id+:             a String used to identify the property's unit with the partner. Not related to Roomorama.
#   +check_in+:            the check-in date for the stay
#   +check_out+:           the check-out date for the stay
#   +guests+:              the number of guests
#   +available+:           whether or not the property is available for the given dates
#   +total+:               the quoted price for the booking
#   +currency+:            the currency used for the quotation
#   +host_fee_percentage+: the host fee percent, which included in quoted price
#
# The quotation is only successful if the +errors+ attribute is empty.
class Quotation
  include Hanami::Entity
  include Hanami::Validations

  attribute :property_id,         type: String
  attribute :unit_id,             type: String
  attribute :check_in,            type: String
  attribute :check_out,           type: String
  attribute :guests,              type: Integer
  attribute :available,           type: Boolean
  attribute :total,               type: Float
  attribute :currency,            type: String
  attribute :host_fee_percentage, type: Float

  def host_fee
    (total - nett_rate).round(2)
  end

  def nett_rate
    coefficient = 1 + (host_fee_percentage.to_f / 100)
    (total / coefficient).round(2)
  end

end
