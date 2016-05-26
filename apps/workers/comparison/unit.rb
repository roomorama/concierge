module Workers::Comparison

  # +Workers::Comparison::Unit+
  #
  # This class can compare two instanes of +Roomorama::Unit+ and calculate a
  # +Roomorama::Diff::Unit+ instance that, when applied, can transform one
  # instance into another.
  class Unit

    attr_reader :original, :new

    # original - the original record. An instace of +Roomorama::Unit+
    # new      - the new representation for original. An instance of +Roomorama::Unit+.
    def initialize(original, new)
      @original = original
      @new      = new
    end

    # calculates the diff between the two given units, from +original+ to +new+.
    # The resulting diff will include added, changed and deleted metadata, as
    # well as associated images.
    def extract_diff

      # 1. creates a +Roomorama::Diff::Unit+ instance that will hold the differences
      #    between +original+ and +new+.
      diff = Roomorama::Diff::Unit.new(original.identifier)

      # 2. applies metadata differences to the diff (see +Workers::Comparison::Attributes+)
      extract_metadata_diff(diff)

      # 3. extract differences between images
      comparison = compare_images(original.images, new.images)

      # 4. Add each new image, if any
      comparison[:create].each do |image|
        diff.add_image(image)
      end

      # 5. Apply changes to images, if any
      comparison[:update].each do |image_diff|
        diff.change_image(image_diff)
      end

      # 6. delete images, if any
      comparison[:delete].each do |identifier|
        diff.delete_image(identifier)
      end

      diff
    end

    private

    def extract_metadata_diff(diff)
      Workers::Comparison::Attributes.new(original, new).apply_to(diff)
    end

    def compare_images(original_images, new_images)
      Workers::Comparison::Image.new(original_images, new_images).extract_diff
    end
  end
end
