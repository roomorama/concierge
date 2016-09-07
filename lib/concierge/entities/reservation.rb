# +Reservation+
#
# This class wrapped wraps the data obtained from Roomorama for creating booking
# on the supplier's side.
#
# Supplier clients are expected to wrap their response in a +Reservation+ object.
#
# Attributes
#
#   +supplier+:         a String containing the name of the supplier who provides the booked property.
#   +property_id+:      a String used to identify the property with the supplier. Not related to Roomorama.
#   +unit_id+:          a String used to identify the property's unit with the supplier.
#                       Not related to Roomorama.
#   +check_in+:         the check-in date for the stay
#   +check_out+:        the check-out date for the stay
#   +guests+:           the number of guests
#   +customer+:         a +Customer+ entity should keep customer's required info
#   +reference_number+: is a booking identifier on the supplier side
#   +extra+:            if for partner required extra options like credit card, payment type, etc.
#                       it should be here.
class Reservation
  include Hanami::Entity
  include Hanami::Validations

  attribute :supplier,         type: String
  attribute :property_id,      type: String
  attribute :unit_id,          type: String
  attribute :check_in,         type: String
  attribute :check_out,        type: String
  attribute :guests,           type: Integer
  attribute :reference_number, type: String
  attribute :attachment_url,   type: String
  attribute :extra,            type: Hash
  attribute :customer,         type: Hash
  attribute :created_at,       type: Time
  attribute :updated_at,       type: Time
end
