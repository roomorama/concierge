module API::Controllers::Params

  # +API::Controllers::Params::Booking
  #
  # Parameters declaration and validation for create booking. This is
  # shared among all partner booking calls, and ensures that required parameters
  # are present and in an acceptable format.
  #
  # If the parameters given are not valid, booking controllers that include this
  # module will return a 422 HTTP status, with a response payload that reports
  # the errors in the parameters.
  class Booking < API::Action::Params

    DATE_FORMAT = /\d\d\d-\d\d-\d\d/

    param :property_id,   type: String,  presence: true
    param :check_in,      type: String,  presence: true, format: DATE_FORMAT
    param :check_out,     type: String,  presence: true, format: DATE_FORMAT
    param :guests,        type: Integer, presence: true
    param :subtotal,      type: Integer, presence: true
    param :currency_code, type: String
    param :inquiry_id,    type: String

    param :extra
    param :customer do
      param :first_name,  type: String, presence: true
      param :last_name,   type: String, presence: true
      param :email,       type: String, presence: true
      param :phone,       type: String
      param :address,     type: String
      param :postal_code, type: String
      param :country,     type: String
      param :city,        type: String
      param :language,    type: String
      param :gender,      type: String
    end

    def error_messages
      ErrorMessages.new(validation_errors).generate
    end

    def validation_errors
      errors.each.to_a + travel_dates.errors
    end

    def valid?
      builtin_validations      = super
      travel_dates_validations = travel_dates.valid?

      builtin_validations && travel_dates_validations
    end

    private

    def travel_dates
      @travel_dates ||= TravelDates.new(self[:check_in], self[:check_out])
    end
  end

end
