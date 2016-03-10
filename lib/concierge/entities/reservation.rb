# +Reservation+
#
# This class wrapped wraps the data obtained from Roomorama for creating booking on partner's side.
# Partner clients are expected to wrap their response in a +Reservation+ object.
#
# Attributes
#
#   +quotation+: a +Quotation+ entity
#   +customer+:  a +Customer+ entity should keep customer's required info
#   +code+:      a String, returns after succeed booking
#
# The quotation is only successful if a +Customer+ and +Quotation+ are successful.
class Reservation
  include Hanami::Entity
  include Hanami::Validations

  attribute :quotation
  attribute :customer
  attribute :code, type: String


  def successful?
    quotation.successful? && customer.successful?
  end

end
