module Workers::Comparison

  # +Workers::Comparison::Image+
  #
  # This class performs a comparison between two list of images. This is
  # necessary when updating image information related to a property or unit.
  #
  # Usage
  #
  #   original = [
  #     Roomorama::Image.load({
  #       identifier: "img1",
  #       url:        "https://www.example.org/image1",
  #       caption:    "Barbecue Pit"
  #     }),
  #     Roomorama::Image.load({
  #       identifier: "img2",
  #       url:        "https://www.example.org/image2",
  #       caption:    "Swimming Pool"
  #     }),
  #     Roomorama::Image.load({
  #       identifier: "img3",
  #       url:        "https://www.example.org/image3"
  #     })
  #   ]
  #   new = [
  #     Roomorama::Image.load({
  #       identifier: "img1",
  #       url:        "https://www.example.org/image1",
  #       caption:    "Barbecue Pit"
  #     },
  #     Roomorama::Image.load({
  #       identifier: "img3",
  #       url:        "https://www.example.org/image3",
  #       caption:    "Foosball Table"
  #     },
  #     Roomorama::Image.load({
  #       identifier: "img4",
  #       url:        "https://www.example.org/image4",
  #       caption:    "Entrance"
  #     })
  #   ]
  #   comparison = Workers::Comparison::Image.new(original, new)
  #   comparison.extract_diff
  #   # => {
  #     create: [
  #       Roomorama::Image.create({
  #         identifier: "img4",
  #         url:        "https://www.example.org/image4",
  #         caption:    "Entrance"
  #       })
  #     ],
  #     update: [
  #       Roomorama::Diff::Image.load({
  #         identifier: "img3",
  #         caption:    "Foosball Table"
  #       })
  #     ],
  #     delete: ["img2"]
  #   }
  #
  # The output above means that the +extract_diff+ method returns a hash where the +create+
  # entry is a collection of +Roomorama::Image+ objects; the +update+ entry is
  # a collection of +Roomorama::Diff::Image+ objects and the +delete+ entry is a collection
  # of image identifiers (+String+).
  class Image

    attr_reader :original, :new

    def initialize(original, new)
      @original = original
      @new      = new
    end

    # calculates the difference between the two lists of images based on
    #
    # - images to be created
    # - images to be updated
    # - images to be deleted.
    #
    # Check the flow in the method for more information on the details of
    # the process.
    def extract_diff

      # 1. index both lists based on their identifiers, in order to create an
      #    index where the key is the identifier and the value is the image data.
      original_index = index(original)
      new_index      = index(new)

      # 2. extract the identifiers both lists.
      original_identifiers = keys(original_index)
      new_identifiers      = keys(new_index)

      # 3. calculate the identifiers for the three sets of images (added, deleted, and common)
      #
      # added   - present on the new list but absent on the original one
      # removed - present on the original list but absent on the original one
      # common  - present on both lists
      added_images   = new_identifiers      - original_identifiers
      removed_images = original_identifiers - new_identifiers
      common_images  = original_identifiers & new_identifiers

      # 4. Images on the +added+ list should be +created+. This adds them to the
      #    diff accordingly, levaraging the previously created index.
      added_images.each do |identifier|
        diff[:create] << new_index[identifier]
      end

      # 5. for each image present on both list, we check the captions. If they
      #    differ, then the new caption is added to the list of changes. Only
      #    image caption changes are supported by Roomorama's diff API.
      common_images.each do |identifier|
        original_caption = original_index[identifier].caption
        new_caption      = new_index[identifier].caption

        if original_caption != new_caption
          image_diff         = Roomorama::Diff::Image.new(identifier)
          image_diff.caption = new_caption

          diff[:update] << image_diff
        end
      end

      # 6. images present on the original list but not on the new one
      #    should be deleted. Add the identifiers to the list.
      removed_images.each do |identifier|
        diff[:delete] << identifier
      end

      # 7. Clean up. If any of the operations (create, update, delete) has
      #    no elements, remove it from the diff. Return the final result.
      diff.delete_if { |_, collection| collection.empty? }
    end

    private

    def diff
      @diff ||= { create: [], update: [], delete: [] }
    end

    def index(images)
      Hash[images.map { |image| [image.identifier, image] }]
    end

    def keys(hash)
      hash.to_h.keys.sort
    end
  end
end
