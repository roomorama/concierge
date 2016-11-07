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
  attribute :currency,    type: String

  #validates :net_rate,    presence: true

  # The fee, already included in quoted total price
  def host_fee
    (total - net_rate).round(2)
  end

  # The quotation without host fee
  def net_rate
    coefficient = 1 - host_fee_percentage.to_f / 100
    (total * coefficient).round(2)
  end

  # The fee percentage, already included in quoted total price
  def host_fee_percentage
    @host_fee_percentage ||= HostRepository.find(property.host_id).fee_percentage
  end

  def property
    @property ||= PropertyRepository.identified_by(property_id).first
  end

end
