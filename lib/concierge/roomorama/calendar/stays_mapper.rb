class Roomorama::Calendar
  # Maps valid stays into Roomorama::Calendar:Entries by adding valid_stay_lengths
  #
  # Example:
  #   stays = [
  #     {
  #       checkin:    "2016-01-01",
  #       checkout:   "2016-01-07",
  #       stay_price: 100,
  #       available:  true
  #     }, {
  #       checkin:    "2016-01-01",
  #       checkout:   "2016-01-14",
  #       stay_price: 100,
  #       available:  true
  #     }]
  #
  #   entries = StaysMapper.new(stays).map
  #
  # See more detailed example in specs
  #
  class StaysMapper

    attr_reader :stays

    def initialize(stays)
      @stays = stays.dup
      @stays.each { |s| s[:rate] = s[:stay_price] / stay_length(s) }
    end

    def map
      dates_with_stay.collect do |date|
        default_entry(date).tap do |entry|
          if stays_by_checkin.include? date.to_s
            entry.checkin_allowed = true
            entry.valid_stay_lengths = collect_stay_lengths(date)
          end

          entry.checkout_allowed = true if stays_by_checkout.include? date.to_s

          entry.nightly_rate = minimum_nightly_rate(date)
        end
      end
    end

    private

    def collect_stay_lengths(date)
      stays_by_checkin[date.to_s].collect do |stay|
        stay_length(stay)
      end
    end

    # stays should have at least one entry include the given date
    #
    def minimum_nightly_rate(date)
      stays.select { |stay| include_date?(stay, date) }.
        min_by { |s| s[:rate] }[:rate]
    end

    def include_date?(stay, date)
      Date.parse(stay[:checkin]) <= date && date <= Date.parse(stay[:checkout])
    end


    def stay_length(stay)
      diff = Date.parse(stay[:checkout]) - Date.parse(stay[:checkin])
      return diff.to_i
    end

    def stays_by_checkin
      @stays_by_checkin || stays.group_by { |s| s[:checkin] }
    end

    def stays_by_checkout
      @stays_by_checkout || stays.group_by { |s| s[:checkout] }
    end

    def dates_with_stay
      (Date.parse(earliest_checkin)..Date.parse(latest_checkout)).select { |d|
        stays.any? { |stay| include_date?(stay, d) }
      }
    end

    def earliest_checkin
      @earliest_checkin || stays_by_checkin.keys.sort.first
    end

    def latest_checkout
      @latest_checkout || stays_by_checkout.keys.sort.last
    end

    def default_entry(date)
      Roomorama::Calendar::Entry.new({
        date:             date.to_s,
        available:        true,
        checkin_allowed:  false,
        checkout_allowed: false,
      })
    end
  end
end

