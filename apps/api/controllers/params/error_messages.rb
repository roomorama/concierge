# +API::Controllers::Params::ErrorMessages+
#
# This class represents array of +params+ errors
class API::Controllers::Params::ErrorMessages
  attr_reader :errors

  def initialize(errors)
    @errors = errors
  end

  def generate
    messages = Hash.new { |h, k| h[k] = [] }

    errors.each do |error|
      attr = error.attribute

      case error.validation
        when :presence
          messages[attr] << "#{attr} is required"
        when :format
          messages[attr] << "#{attr}: invalid format"
        when :check_out_before_check_in
          messages[attr] << "#{attr} needs to be after check-in"
        else
          messages[attr] << "#{attr} is invalid"
      end
    end

    messages
  end
end
