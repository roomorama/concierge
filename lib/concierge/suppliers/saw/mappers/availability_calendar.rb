module SAW
  module Mappers
    # +SAW::Mappers::AvailabilityCalendar+
    #
    # This class is responsible for building an availability calendar of the
    # property.
    class AvailabilityCalendar
      class << self
        # Builds a Hash of property availability
        # Availabilities are build for the next three months from the current
        # time.
        #
        # Usage
        #   
        #   SAW::Mappers::AvailabilityCalendar.build
        #   => {
        #     "2016-06-29"=>true,
        #     "2016-06-30"=>true,
        #     "2016-07-01"=>true,
        #     "2016-07-02"=>true,
        #     ...
        #   }
        #
        # Returns a +Hash+ with a key-value pairs where key is a date and value is 
        # a flag whether property is available or not for that day.
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
