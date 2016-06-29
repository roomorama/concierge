# +Calendar+
#
# This class wraps the estimated availabilities calendar based on API calls
# to suppliers, for a given property.
#
# Attributes
#
#   +property_id+: a String used to identify the property with the supplier. Not related to Roomorama.
#   +entries+:     an Array of +Calendar::Entry+ objects.
#   +errors+:      if there were any errors during the quotation with the partner,
#                  the errors will be listed here.
class Calendar

  # +Calendar::Entry+
  #
  # This object encapsulates the availability information for a single date.
  # It has meaning only when part of a +Calendar+ object, which contains the
  # +property_id+ of which the entry is related to.
  #
  # Attributes
  #
  #   +date+:             The date to which the entry refers.
  #   +available+:        whether or not the date is available for booking.
  #   +nightly_rate+:     the price for the night on the given date
  #   +weekly_rate+:      the price for a week applicable on the given date
  #   +monthly_rate+:     the price for a month applicable on the given date
  #   +checkin_allowed+:  whether or not checking-in is allowed on the given date
  #   +checkout_allowed+: whether or not checking-out is allowed on the given date
  class Entry
    include Hanami::Entity
    include Hanami::Validations

    attribute :date,             type: Date
    attribute :available,        type: Boolean
    attribute :nightly_rate,     type: Float
    attribute :weekly_rate,      type: Float
    attribute :monthly_rate,     type: Float
    attribute :checkin_allowed,  type: Boolean
    attribute :checkout_allowed, type: Boolean
  end

  # +Calendar::InvalidEntryError+
  #
  # This error is raised whenever +Calendar#add+ is called passing an argument
  # which is not of the expected +Calendar::Entry+ type.
  class InvalidEntryError < StandardError
    def initialize(object)
      super("Expected instance of Calendar::Entry, received #{object.class}")
    end
  end

  include Hanami::Entity
  include Hanami::Validations

  attribute :property_id, type: String
  attribute :entries,     type: Array
  attribute :errors,      type: Hash

  # always initialize a new instance with an empty set of entries.
  def initialize(attributes = {})
    super
    self.entries = []
  end

  # includes an entry in the calendar.
  #
  # entry - an instance of +Calendar::Entry+.
  def add(entry)
    raise InvalidEntryError.new(entry) unless entry.is_a?(Entry)
    entries << entry
  end

  def successful?
    Array(errors).empty?
  end
end
