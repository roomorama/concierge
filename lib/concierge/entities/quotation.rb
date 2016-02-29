class Quotation
  include Hanami::Entity
  include Hanami::Validations

  attribute :property_id, type: String
  attribute :check_in,    type: Date
  attribute :check_out,   type: Date
  attribute :guests,      type: Integer
  attribute :currency,    type: String
  attribute :total,       type: Integer
  attribute :errors,      type: Hash

  def successful?
    Array(errors).empty?
  end
end
