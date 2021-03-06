require_relative "error"

module Roomorama

  # +Roomorama::Calendar+
  #
  # This class represents the availabilities calendar for a given property from
  # a supplier. It is able to store availabilities, rates and check-in/check-out rules
  # for a range of dates.
  #
  # Usage
  #
  #   calendar = Roomorama::Calendar.new(property_identifier)
  #   entry = Roomorama::Calendar::Entry.new(
  #     date:               "2016-05-22",
  #     available:          true,
  #     nightly_rate:       100,
  #     weekly_rate:        500,
  #     monthly_rate:       1000,
  #     checkin_allowed:    true,
  #     valid_stay_lengths: [1, 7],
  #     checkout_allowed:   false
  #   )
  #
  #   calendar.add(entry)
  #
  #   # for multi-unit properties
  #   unit_calendar = Roomorama::Calendar.new(unit_identifier)
  #   entry = Roomorama::Calendar::Entry.new(
  #     date:             "2016-05-22",
  #     available:        false,
  #     nightly_rate:     200
  #   )
  #   unit_calendar.add(entry)
  #   calendar.add_unit(unit_calendar)
  #
  # Note that +weekly_rate+, +monthly_rate+, +checkin_allowed+ and +checkout_allowed+
  # are optional fields in +Roomorama::Calendar::Entry+. If the supplier API does not
  # provide them, defaults should *not* be assumed and the fields can be left blank.
  class Calendar
    class Entry
      include Hanami::Validations

      DATE_FORMAT = /\d\d\d\d-\d\d-\d\d/

      attribute :date,         presence: true, type: Date, format: DATE_FORMAT
      attribute :available,    presence: true, type: Boolean
      attribute :nightly_rate, presence: true
      attribute :weekly_rate
      attribute :monthly_rate
      attribute :minimum_stay
      attribute :checkin_allowed
      attribute :checkout_allowed
      attribute :valid_stay_lengths

      def initialize(attributes)
        initialize_checkin_rules(attributes)
        super
      end

      private

      # if specific values for +checkin_allowed+ and +checkout_allowed+ are not
      # given, this sets these attributes to +true+.
      def initialize_checkin_rules(attributes)
        [:checkin_allowed, :checkout_allowed].each do |name|
          unless attributes.has_key?(name)
            attributes[name] = true
          end
        end
      end
    end

    # +Roomorama::Calendar::ValidationError+
    #
    # Raised when a calendar fails to meet expected parameter requirements.
    class ValidationError < Roomorama::Error
      def initialize(message)
        super("Calendar validation error: #{message}")
      end
    end

    attr_reader :identifier, :entries, :units

    # identifier - the property/unit identifier to which the calendar refers to.
    def initialize(identifier)
      @entries    = []
      @units      = []
      @identifier = identifier
    end

    # includes a new calendar entry in the calendar instance. +entry+ is expected
    # to be a +Roomorama::Calendar::Entry+ instance.
    def add(entry)
      entries << entry
    end

    # calendar - an instance of +Roomorama::Calendar+
    #
    # includes the availabilities calendar for a unit of the parent property.
    def add_unit(calendar)
      @units << calendar
    end

    # validates if all entries passed to this calendar instance via +add+ are valid.
    # In case one of them is not, this method will raise a +Roomorama::Calendar::ValidationError+
    # error.
    def validate!
      entries.all?(&:valid?) || (raise ValidationError.new("One of the entries miss required parameters."))
    end

    # Non multiunit property's calendar is empty if its entries list is empty
    # Muiltiunit property's calendar is empty if calendar of each unit is empty
    def empty?
      entries.empty? && (units.empty? || units.all?(&:empty?))
    end

    def to_h
      parsed = parse_entries

      {
        identifier:         identifier,
        start_date:         parsed.start_date.to_s,
        availabilities:     parsed.availabilities,
        nightly_prices:     parsed.rates.nightly,
        weekly_prices:      parsed.rates.weekly,
        monthly_prices:     parsed.rates.monthly,
        minimum_stays:      parsed.minimum_stays,
        valid_stay_lengths: parsed.valid_stay_lengths,
        checkin_allowed:    parsed.checkin_rules,
        checkout_allowed:   parsed.checkout_rules,

        # units should be instances of +Roomorama::Calendar+ as well, so they
        # are serialised with +to_h+, this very method.
        units: units.map(&:to_h)
      }.tap do |payload|

        # we do not need to send a potentially large array of +nulls+ if a supplier
        # does not provide weekly/monthly data. In that sense:
        #
        # * optional prices/minimum stays that are all null should be discarded
        # * check-in/check-out rules where all elements are +true+ should be discarded,
        #   since that is already the default of the API endpoint.

        [:weekly_prices, :monthly_prices, :minimum_stays].each do |name|
          if payload[name].all?(&:nil?)
            payload.delete(name)
          end
        end

        [:checkin_allowed, :checkout_allowed].each do |name|
          if payload[name].to_s.chars.all? { |e| e == "1" }
            payload.delete(name)
          end
        end

        # if a property is not multi-unit, no need to include an empty
        # +units+ field
        if payload[:units].empty?
          payload.delete(:units)
        end

        if payload[:valid_stay_lengths].all?(&:empty?)
          payload.delete(:valid_stay_lengths)
        end

      end
    end

    private

    Rates         = Struct.new(:nightly, :weekly, :monthly)
    ParsedEntries = Struct.new(
      :start_date, :availabilities, :checkin_rules, :checkout_rules, :minimum_stays, :rates, :valid_stay_lengths
    )

    # parses the collection of +entries+ given on the lifecycle of this instance,
    # and builds a +Roomorama::Calendar::ParsedEntries+ instance, containing data
    # after parsing.
    def parse_entries
      return empty_response if entries.empty?

      sorted_entries = entries.select(&:valid?).sort_by(&:date)
      start_date     = sorted_entries.first.date
      end_date       = sorted_entries.last.date

      rates          = Rates.new([], [], [])
      parsed_entries = ParsedEntries.new(start_date, "", "", "", [], rates, [])

      # index all entries by date, to make the lookup for a given date faster.
      # Index once, and then all lookups can be performed in constant time,
      # as opposed to scanning the list of entries on every iteration.
      #
      # Implementation of what Rails provide as the +index_by+ method.
      index = {}.tap do |i|
        entries.each do |entry|
          i[entry.date] = entry
        end
      end

      (start_date..end_date).each do |date|
        entry = index[date] || default_entry(date)

        parsed_entries.availabilities     << boolean_to_string(entry.available)
        parsed_entries.rates.nightly      << entry.nightly_rate
        parsed_entries.rates.weekly       << entry.weekly_rate
        parsed_entries.rates.monthly      << entry.monthly_rate
        parsed_entries.minimum_stays      << entry.minimum_stay
        parsed_entries.valid_stay_lengths << entry.valid_stay_lengths.to_a
        parsed_entries.checkin_rules      << boolean_to_string(entry.checkin_allowed)
        parsed_entries.checkout_rules     << boolean_to_string(entry.checkout_allowed)

      end

      parsed_entries
    end

    # when there are no calendar entries given, the serialization should return
    # the empty counterpart of the fields.
    def empty_response
      rates = Rates.new([], [], [])
      ParsedEntries.new("", "", "", "", [], rates, [])
    end

    # builds a placeholder calendar entry to be used when there are gaps
    # in the entries provided to this instance. The date is assumed to be
    # available, and the price is the average of all prices given to this
    # class. Checking in and out is also assumed to be possible.
    def default_entry(date)
      average_rate = entries.map(&:nightly_rate).reduce(:+) / entries.size

      Roomorama::Calendar::Entry.new(
        date:             date.to_s,
        available:        true,
        nightly_rate:     average_rate,
        checkin_allowed:  true,
        checkout_allowed: true
      )
    end

    def boolean_to_string(bool)
      bool ? "1" : "0"
    end
  end

end
