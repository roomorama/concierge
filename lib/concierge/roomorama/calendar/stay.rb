class Roomorama::Calendar::Stay
  include Hanami::Validations

  DATE_FORMAT = /\d\d\d\d-\d\d-\d\d/
  attribute :checkin,   presence: true, type: Date, format: DATE_FORMAT
  attribute :checkout,  presence: true, type: Date, format: DATE_FORMAT
  attribute :price,     presence:true,  type: Float

  def length
    (checkout - checkin).to_i
  end

  def rate
    (price / length).round(2)
  end

  def include?(date)
    checkin <= date && date <= checkout
  end
end
