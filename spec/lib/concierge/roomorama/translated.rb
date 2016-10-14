RSpec.shared_examples "translated object" do

  # The spec including these examples should provide a valid `subject`
  #
  describe "adding locales" do
    it "allows adding translations to the diff" do
      subject[:title]    = "New Title"
      subject.es[:title] = "Nuevo título"
      expect(subject.title).to eq "New Title"
      expect(subject.es.title).to eq "Nuevo título"
    end
  end

end
