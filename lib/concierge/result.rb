# +Result+
#
# An implementation of a simple result object, intended to write the result
# of operations. The intended use for result object is to allow the caller to
# determine the status of an operation, whether it was successful or not
# and what was the error, if any.
#
# Usage
#
#   result = some_operation
#
#   if result.success?
#     do_something(result.value)
#   else
#     handle_error(error.code)
#   end
#
# +Result::Error+ is an object that holds a representative error code and an optional
# descriptive +data+ field. A code is a unique representation of the error, that can
# later be used to identify and group similar occurrences of errors; the +data+ field
# might contain any type +T+ (or even be +nil+). Its use is optional and the caller might
# choose to include extra data with the error or not.
class Result

  Error = Struct.new(:code, :data)

  # Shortcut method for creating an error result object.
  #
  # Example
  #
  #   def method
  #     call_third_party
  #   rescue Partner::Error => e
  #     data = { error_message: e.message }
  #     Result.error(:partner_error, data)
  #   end
  def self.error(code, data = nil)
    self.new.tap do |result|
      result.error.code = code
      result.error.data = data
    end
  end

  attr_reader :result

  def initialize(result = nil)
    @result = result
  end

  # Determines if the operation was successful. Every error must have a code,
  # so if there is a code associated with this operation error, the operation
  # was not successful.
  def success?
    error.code.nil?
  end

  # Returns the wrapped result of the operation. If it was not successful
  # this wil return +nil+.
  def value
    if success?
      result
    end
  end

  def error
    @error ||= Error.new
  end

end
