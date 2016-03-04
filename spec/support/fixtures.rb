module Support
  module Fixtures

    # Helper method for reading fixture files, from the +spec/fixtures+
    # directory.
    #
    #   read_fixture("supplier/example_a.json")
    #
    # Returns a +String+ with the content of the given file.
    def read_fixture(name)
      path = Hanami.root.join("spec", "fixtures", name)
      File.read(path)
    end

  end
end
