class Roomorama::Calendar::Stay
  include Hanami::Validations

  DATE_FORMAT = /\d\d\d\d-\d\d-\d\d/
  attribute :checkin,    presence: true, type: Date, format: DATE_FORMAT
  attribute :checkout,   presence: true, type: Date, format: DATE_FORMAT
  attribute :stay_price, presence:true
  attribute :available,  presence:true
  attribute :rate

  def initialize(attributes)
    super
    self.rate ||= stay_price / stay_length
  end

  def stay_length
    (checkout - checkin).to_i
  end

  def include?(date)
    checkin <= date && date <= checkout
  end
end
