# +Customer+
#
# This class wraps the customer data which are required for creating booking for partners.
# This is part of +Reservation+ entity.
#
# Attributes
#
#   +first_name+
#   +last_name+
#   +gender+:
#   +country+:
#   +city+:
#   +address+:
#   +postal_code+: is a String
#   +email+:
#   +phone+:
#   +language+:    is a String, takes from user's locale
#   +errors+:      if there were any errors during the initialization,
#                  the errors will be listed here.
#
#  todo: define rquired fields
class Customer
  include Hanami::Entity
  include Hanami::Validations

  attribute :first_name,  type: String
  attribute :last_name,   type: String
  attribute :gender,      type: String
  attribute :country,     type: String
  attribute :city,        type: String
  attribute :address,     type: String
  attribute :postal_code, type: String
  attribute :email,       type: String
  attribute :phone,       type: String
  attribute :language,    type: String
  attribute :errors,      type: Hash

  def successful?
    Array(errors).empty?
  end
end
