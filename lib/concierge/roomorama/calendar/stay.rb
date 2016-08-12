class Roomorama::Calendar::Stay
  include Hanami::Validations

  DATE_FORMAT = /\d\d\d\d-\d\d-\d\d/
  attribute :checkin,   presence: true, type: Date, format: DATE_FORMAT
  attribute :checkout,  presence: true, type: Date, format: DATE_FORMAT
  attribute :price,     presence:true
  attribute :available, presence:true
  attribute :rate

  def initialize(attributes)
    super
    self.rate ||= price / length
  end

  def length
    (checkout - checkin).to_i
  end

  def include?(date)
    checkin <= date && date <= checkout
  end
end
