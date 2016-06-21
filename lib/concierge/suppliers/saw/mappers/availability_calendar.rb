module SAW
  module Mappers
    class AvailabilityCalendar
      class << self
        def build
          current_time = Time.now

          build_calendar(current_time)
        end
      
        private
        def seconds_in_one_day
          24 * 60 * 60
        end

        def days_in_three_months
          3 * 30
        end

        def build_calendar(start_time)
          calendar = {}

          days_in_three_months.times do |time|
            date = start_time + time * seconds_in_one_day
            calendar[date.to_date.to_s] = true  
          end

          calendar
        end
      end
    end
  end
end
