RSpec.shared_examples "translated object" do

  # The spec including these examples should provide a valid `subject`
  #
  describe "adding locales" do
    it "allows adding translations to the object" do
      subject[:title]    = "New Title"
      subject.es[:title] = "Nuevo título"
      subject.de[:title] = "neuer Titel"
      expect(subject.title).to eq "New Title"
      expect(subject.es.title).to eq "Nuevo título"
      expect(subject.de.title).to eq "neuer Titel"

      subject.es[:description] = "nueva descripción"
      subject.de[:description] = "neuer Beschreibung"
      expect(subject.es.description).to eq "nueva descripción"
      expect(subject.de.description).to eq "neuer Beschreibung"
    end
  end

end
