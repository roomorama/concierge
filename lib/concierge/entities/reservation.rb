# +Reservation+
#
# This class wrapped wraps the data obtained from Roomorama for creating booking on partner's side.
# Partner clients are expected to wrap their response in a +Reservation+ object.
#
# Attributes
#
#   +property_id+: a String used to identify the proeprty with the partner. Not related to Roomorama.
#   +unit_id+:     a String used to identify the proeprty's unit with the partner. Not related to Roomorama.
#   +check_in+:    the check-in date for the stay
#   +check_out+:   the check-out date for the stay
#   +guests+:      the number of guests
#   +customer+:    a +Customer+ entity should keep customer's required info
#   +code+:        is a booking identifier on the supplier side
#   +extra+:       if for partner required extra options like credit card, payment type... it should be here.
#   +errors+:      if there were any errors during the booking creation with the partner,
#                  the errors will be listed here.
#
# The reservation is only successful if the +errors+ attribute is empty and +customer+ is successful.
class Reservation
  include Hanami::Entity
  include Hanami::Validations

  attribute :property_id, type: String
  attribute :unit_id,     type: String
  attribute :check_in,    type: String
  attribute :check_out,   type: String
  attribute :guests,      type: Integer
  attribute :code,        type: String
  attribute :extra,       type: Hash
  attribute :errors,      type: Hash
  attribute :customer,    type: Hash


  def successful?
    Array(errors).empty?
  end

end
