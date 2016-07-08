module Roomorama

  # +Roomorama::Mappers+
  #
  # Implements image and availability mappers that are shared between Roomorama's
  # properties and units.
  module Mappers
    def map_images(place)
      place.images.map(&:to_h)
    end

    # maps changes according to the format expected by the Roomorama Diff API.
    # Same format for both properties and units.
    def map_changes(changeset)
      changes = {}

      changes[:create] = changeset.created.map(&:to_h)
      changes[:update] = changeset.updated.map(&:to_h)
      changes[:delete] = changeset.deleted.map(&:to_s)

      scrub_collection(changes)
    end

    def scrub(data, erased = [])
      data.delete_if { |key, value| value.to_s.empty? && !erased.include?(key.to_s) }
    end

    def scrub_collection(data)
      data.delete_if { |_, value| Array(value).empty? }
    end
  end

end
