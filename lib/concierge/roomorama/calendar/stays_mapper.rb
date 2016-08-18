class Roomorama::Calendar
  # Maps valid stays into Roomorama::Calendar:Entries by adding valid_stay_lengths
  #
  # Example:
  #   stays = [
  #     Roomrama::Calendar::Stay.new({
  #       checkin:    "2016-01-01",
  #       checkout:   "2016-01-08",
  #       price: 700, # 100 per night
  #     }),
  #     Roomrama::Calendar::Stay.new({
  #       checkin:    "2016-01-01",
  #       checkout:   "2016-01-15",
  #       price: 700, # 50 per night
  #     })
  #   ]
  #
  #   entries = StaysMapper.new(stays, Date.today).map
  #
  # See more detailed example in specs
  #
  class StaysMapper

    attr_reader :stays, :day

    # mapper starts fill entries from day after day, so usually `day = Date.today`
    def initialize(stays, day)
      @stays = stays
      @day = day
    end

    def map
      (from_date..latest_checkout).collect do |date|
        default_entry(date).tap do |entry|
          entry.available = dates_with_stay.include? date

          if stays_by_checkin.include? date
            entry.checkin_allowed = true
            entry.valid_stay_lengths = collect_stay_lengths(date)
          end

          entry.checkout_allowed = true if stays_by_checkout.include? date

          entry.nightly_rate = minimum_nightly_rate(date) if entry.available
        end
      end
    end

    private

    def collect_stay_lengths(date)
      stays_by_checkin[date].collect(&:length)
    end

    # stays should have at least one entry include the given date
    #
    def minimum_nightly_rate(date)
      stays.select { |stay| stay.include?(date) }.
        min_by { |s| s.rate }.rate
    end

    def stays_by_checkin
      @stays_by_checkin ||= stays.group_by(&:checkin)
    end

    def stays_by_checkout
      @stays_by_checkout ||= stays.group_by(&:checkout)
    end

    def dates_with_stay
      @dates_with_stay ||= Set.new((from_date..latest_checkout).select { |date|
        stays.any? { |stay| stay.include?(date) }
      })
    end

    def from_date
      day + 1
    end

    def latest_checkout
      @latest_checkout ||= stays_by_checkout.keys.sort.last
    end

    def default_entry(date)
      Roomorama::Calendar::Entry.new({
        date:             date.to_s,
        available:        true,
        checkin_allowed:  false,
        checkout_allowed: false,
        nightly_rate:     0
      })
    end
  end
end

