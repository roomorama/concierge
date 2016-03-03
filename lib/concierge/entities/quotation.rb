# +Quotation+
#
# This class wraps the price obtained from a partner for a booking. Partner clients
# are expected to wrap their response in a +Quotation+ object.
#
# Attributes
#
#   +property_id+: a String used to identify the proeprty with the partner. Not related to Roomorama.
#   +check_in+:    the check-in date for the stay
#   +check_out+:   the check-out date for the stay
#   +guests+:      the number of guests
#   +available+:   whether or not the property is available for the given dates
#   +total+:       the quoted price for the booking
#   +currency+:    the currency used for the quotation
#   +errors+:      if there were any errors during the quotation with the partner,
#                  the errors will be listed here.
#
# The quotation is only successful if the +errors+ attribute is empty.
class Quotation
  include Hanami::Entity
  include Hanami::Validations

  attribute :property_id, type: String
  attribute :check_in,    type: Date
  attribute :check_out,   type: Date
  attribute :guests,      type: Integer
  attribute :available,   type: Boolean
  attribute :total,       type: Integer
  attribute :currency,    type: String
  attribute :errors,      type: Hash

  def successful?
    Array(errors).empty?
  end
end
