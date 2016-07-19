module Workers::Comparison

  # +Workers::Comparison::Attributes+
  #
  # This class is used to calculate the different meta attributes of a +Roomorama::Property+
  # or a +Roomorama::Unit+, leveraging the shared interface between such classes and that
  # of their diff counterparts.
  class Attributes

    attr_reader :original, :new

    # original and new - instances of +Roomorama::Unit+ or +Roomorama::Property+.
    #
    # Expected methods:
    #
    # +to_h+, returning a Hash representation of the instance.
    # public accessor for attributes of the returned hashes (apart from keys whose
    # values are arrays or other hashes - those should represent associations.)
    def initialize(original, new)
      @original = original
      @new      = new
    end

    # applies the difference between the two instances given on initialization to
    # the given +diff+ instance, which should be an instance of either +Roomorama::Diff+
    # or +Roomorama::Diff::Unit+. The +diff+ is expected to:
    #
    # have the +[]=+ method, allowing attributes to be set using a Hash-like syntax;
    # respond to the +erase+ method, indicating that an attribute should be +nil+ when
    # serialized, causing it to be erased.
    #
    # Returns a boolean indicating whether or not there were any changes applied.
    def apply_to(diff)

      changed = false
      original_serialized = original.to_h
      new_serialized      = new.to_h

      # 1. find attributes which map to scalar values (i.e., removes Arrays and Hashes).
      original_attributes = meta_keys(original_serialized)
      new_attributes      = meta_keys(new_serialized)

      # 2. find the sets of attributes that were: added, removed or are common (shared
      #    between both instances.)
      added_meta   = new_attributes      - original_attributes
      removed_meta = original_attributes - new_attributes
      common_meta  = original_attributes & new_attributes

      # 3. for each attribute present only on the new instance, we set the +diff+
      #    to the content of the new object.
      added_meta.each do |attr|
        changed    = true
        diff[attr] = new_serialized[attr]
      end

      # 4. for each attribute that was originally set but is not anymore, we +erase+ it
      removed_meta.each do |attr|
        changed = true
        diff.erase(attr)
      end

      # 5. for each common attribute, shared between both instances, we check
      #    their values: if they differ, than the new value should be included
      #    in the +diff+.
      common_meta.each do |attr|
        original_attr = original_serialized[attr]
        new_attr      = new_serialized[attr]

        if original_attr != new_attr
          changed = true
          diff[attr] = new_attr
        end
      end

      changed
    end

    private

    def meta_keys(map)
      map.delete_if { |_, value| value.is_a?(Array) || value.is_a?(Hash) }.keys.sort
    end

  end
end
