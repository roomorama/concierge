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

    param :property_id, presence: true, type: String
    param :check_in,    presence: true, type: String, format: DATE_FORMAT
    param :check_out,   presence: true, type: String, format: DATE_FORMAT
    param :guests,      presence: true, type: Integer
    param :subtotal,    presence: true, type: Integer

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
      errors.each.to_a + date_comparison.errors
    end

    def valid?
      builtin_validations = super
      date_validations    = date_comparison.valid?

      builtin_validations && date_validations
    end

    private

    def date_comparison
      @date_comparison ||= DateComparison.new(check_in: self[:check_in], check_out: self[:check_out])
    end
  end

end
