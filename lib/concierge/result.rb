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
#     handle_error(error.code, error.message)
#   end
#
# +Result::Error+ is an object with a code and a message. A code is a unique
# representation of the error, whereas the message can be any further information
# related to the error.
class Result

  Error = Struct.new(:code, :message)

  attr_reader :result

  def initialize(result = nil)
    @result = result
  end

  # Determines if the operation was succesful. Every error must have a code,
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
