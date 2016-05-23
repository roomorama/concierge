module Roomorama

  # +Roomorama::Mappers+
  #
  # Implements image and availabily mappers that are shared between Roomorama's
  # properties and units.
  module Mappers
    def map_images(place)
      place.images.map(&:to_h)
    end

    # check the publish API documentation for a description of the format
    # expected by the availabilities field.
    def map_availabilities(place)
      sorted_dates = place.calendar.keys.map { |date| Date.parse(date) }.sort
      min_date     = sorted_dates.min
      max_date     = sorted_dates.max

      data = ""
      (min_date..max_date).each do |date|
        availability = place.calendar[date.to_s]

        if availability == true
          data << "1"
        elsif availability == false
          data << "0"
        else
          # if the date is not specified, assume it to be available
          # (real-time checking would involve an API call to the supplier)
          data << "1"
        end
      end

      {
        start_date: min_date.to_s,
        data:       data
      }
    end

    def scrub(data)
      data.delete_if { |_, value| value.to_s.empty? }
    end
  end

end
