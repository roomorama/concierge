module Web::Controllers::Params

  class Quote < Web::Action::Params

    DATE_FORMAT = /\d\d\d-\d\d-\d\d/

    param :property_id, presence: true, type: String
    param :check_in,    presence: true, type: String, format: DATE_FORMAT
    param :check_out,   presence: true, type: String, format: DATE_FORMAT
    param :guests,      presence: true, type: Integer

    def error_messages
      messages = Hash.new { |h, k| h[k] = [] }

      errors.each do |error|
        attr = error.attribute

        case error.validation
        when :presence
          messages[attr] << "#{attr} is required"
        when :format
          messages[attr] << "#{attr}: invalid format"
        else
          messages[attr] << "#{attr} is invalid"
        end
      end

      messages
    end

    def check_in
      self[:check_in] && Date.parse(self[:check_in])
    end

    def check_out
      self[:check_out] && Date.parse(self[:check_out])
    end

    def stay_length
      if check_in && check_out
        check_out - check_in
      end
    end

  end

end
