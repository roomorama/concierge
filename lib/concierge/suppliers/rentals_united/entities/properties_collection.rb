module RentalsUnited
  module Entities
    # +RentalsUnited::Entities::PropertiesCollection+
    #
    # This entity represents a properties collection object.
    class PropertiesCollection
      def initialize(entries)
        @entries = entries
      end

      def each_entry
        if block_given?
          @entries.each do |e|
            yield(e[:property_id], e[:location_id])
          end
        else
          return @entries.each
        end
      end

      def size
        @entries.size
      end

      def property_ids
        @entries.map { |e| e[:property_id] }
      end

      def location_ids
        @entries.map { |e| e[:location_id] }.uniq
      end
    end
  end
end
