module Workers::Comparison

  # +Workers::Comparison::Property+
  #
  # This is the main comparison class of the classes under +Concierge+. It takes two
  # instances of +Roomorama::Property+ which are supposed to be successive representations
  # of the same property, and is able to produce a +Roomorama::Diff+ that, when applied
  # can transform one representation to the other
  #
  # Usage
  #
  #   original = Roomorama::Property.load({ ... })
  #   new      = Roomorama::Property.load({ ... })
  #
  #   diff = Workers::Comparison::Property.new(original, new).extract_diff
  #   # => #<Roomorama::Diff ...>
  #
  # This class is capable of identifying differences on associations as well -
  # property images and units (as well as unit images, in turn)
  class Property

    attr_reader :original, :new

    # +original+ and +new+ are expected to be instances of +Roomorama::Property+
    def initialize(original, new)
      @original = original
      @new      = new
    end

    # generates the +Roomorama::Diff+ instance that represents the difference
    # between +original+ and +new+ given on initialization.
    #
    # Most of the work is done in the classes +Workers::Comparison::Image+,
    # +Workers::Comparison::Unit+ and +Workers::Comparison::Attributes+. Check
    # the their documentation to check how the difference is calculated.
    def extract_diff
      diff = Roomorama::Diff.new(original.identifier)

      extract_metadata_diff(original, new, diff)
      compare_images(original.images, new.images, diff)

      if original.multi_unit?
        compare_units(original.units, new.units, diff)
      end

      diff
    end

    private

    def extract_metadata_diff(original, new, diff)
      Workers::Comparison::Attributes.new(original, new).apply_to(diff)
    end

    def compare_images(original_images, new_images, diff)
      comparison = Workers::Comparison::Image.new(original_images, new_images).extract_diff

      Array(comparison[:create]).each do |image|
        diff.add_image(image)
      end

      Array(comparison[:update]).each do |image_diff|
        diff.change_image(image_diff)
      end

      Array(comparison[:delete]).each do |identifier|
        diff.delete_image(identifier)
      end
    end

    def compare_units(original_units, new_units, diff)
      comparison = Workers::Comparison::Unit.new(original_units, new_units).extract_diff

      Array(comparison[:create]).each do |unit|
        diff.add_unit(unit)
      end

      Array(comparison[:update]).each do |unit_diff|
        diff.change_unit(unit_diff)
      end

      Array(comparison[:delete]).each do |identifier|
        diff.delete_unit(identifier)
      end
    end

  end
end
