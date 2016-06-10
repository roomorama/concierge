module Workers::Comparison

  # +Workers::Comparison::Unit+
  #
  # Performs a comparison between two sets of units, useful when comparing
  # multi-unit properties. Given the two sets of +Roomorama::Unit+ instances,
  # this class is able to produce a list of units to be created, updated and
  # deleted so that one set can be transformed into the other.
  class Unit

    attr_reader :original, :new

    # original and new - lists of +Roomorama::Unit+ instances.
    def initialize(original, new)
      @original = original
      @new      = new
    end

    # extracts the list of units to be added, updated and deleted. Returns
    # a Hash with three keys:
    #
    # +create+: a list of +Roomorama::Unit+ instances representing units that
    #           were added.
    # +update+: a list of +Roomorama::Diff::Unit+ instances representing the
    #           set of changes to existing units that should be applied.
    # +delete+: a list of unit identifiers (+String+) of units that were removed.
    def extract_diff

      # 1. index the original and the new list of units according to their identifiers.
      original_index = index(original)
      new_index      = index(new)

      # 2. extracts the list of identifiers for each list.
      original_identifiers = keys(original_index)
      new_identifiers      = keys(new_index)

      # 3. determines which units were added, removed, or are present on both lists.
      added_units   = new_identifiers - original_identifiers
      removed_units = original_identifiers - new_identifiers
      common_units  = original_identifiers & new_identifiers

      # 4. for each unit that is present only on the new set, indicate that
      #    they should be created.
      added_units.each do |identifier|
        diff[:create] << new_index[identifier]
      end

      # 5. for each unit that is present on both lists, use +Workers::Comparison::Attributes+
      #    to compare the two units and extract the differences, if any.
      common_units.each do |identifier|
        original_unit = original_index[identifier]
        new_unit      = new_index[identifier]

        changed, unit_diff = compare_units(original_unit, new_unit)
        if changed
          diff[:update] << unit_diff
        end
      end

      # 6. for each unit that is present only on the original set, indicate that
      #    they should be removed.
      removed_units.each do |identifier|
        diff[:delete] << identifier
      end

      # 7. clean up the final result to include only keys for which there are changes.
      diff.delete_if { |_, collection| collection.empty? }
    end

    private

    def compare_units(original_unit, new_unit)
      diff = Roomorama::Diff::Unit.new(original_unit.identifier)
      changed = extract_metadata_diff(original_unit, new_unit, diff)

      comparison = compare_images(original_unit.images, new_unit.images)

      Array(comparison[:create]).each do |image|
        changed = true
        diff.add_image(image)
      end

      Array(comparison[:update]).each do |image_diff|
        changed = true
        diff.change_image(image_diff)
      end

      Array(comparison[:delete]).each do |identifier|
        changed = true
        diff.delete_image(identifier)
      end

      [changed, diff]
    end


    def extract_metadata_diff(original_unit, new_unit, diff)
      Workers::Comparison::Attributes.new(original_unit, new_unit).apply_to(diff)
    end

    def compare_images(original_images, new_images)
      Workers::Comparison::Image.new(original_images, new_images).extract_diff
    end

    def index(units)
      Hash[units.map { |unit| [unit.identifier, unit] }]
    end

    def keys(hash)
      hash.to_h.keys.sort
    end

    def diff
      @diff ||= { create: [], update: [], delete: [] }
    end
  end
end
